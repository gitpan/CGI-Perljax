package CGI::Perljax;
use strict;
use base qw(Class::Accessor);
use overload '""' => 'show_javascript'; # for building web pages, so
                                        # you can just say: print $pjx

BEGIN {
    use vars qw ($VERSION @ISA);
    $VERSION     = .15;
    @ISA         = qw(Class::Accessor);
}

#create our object's accessor functions
#Perljax->mk_accessors(qw(coderef_list cgi html DEBUG JSDEBUG));

########################################### main pod documentation begin ##
# Below is the stub of documentation for your module. You better edit it!


=head1 NAME

CGI::Perljax - a perl-specific system for writing AJAX- or DHTML-based
web applications.

=head1 SYNOPSIS

  use CGI::Perljax;
  my $pjx = new CGI::Perljax( 'exported_func1' => \&perl_func1 );

=head1 DESCRIPTION

Perljax is an object-oriented module that provides a unique mechanism
for using perl code asynchronously from javascript-enhanced
web pages.  You woul commonly use Perljax in AJAX/DHTML-based web
applications.  Perljax unburdens the user from having to write any
javascript, except for having to associate an exported method with
a document-defined event (such as onClick, onKeyUp, etc). Only in
the more advanced implementations of a exported perl method would
a user need to write any javascript.

Perljax supports methods that return single results, or multiple
results to the web page.

Using Perljax, the URL for the HTTP GET request is automatically
generated based on HTML layout and events, and the page is then
dynamically updated.

Other than using the Class::Accessor module to generate Perljaxs'
accessor methods, Perljax is completely self-contained - it does
not require you to install a larger package or a full Content
Management System.

=head1 USAGE

First, you create a cgi script:  the only requirements for Perljax
are that you hand it a CGI.pm object, and that the subroutines
to be exported to javascript are declared prior to creating the
Perljax object, like so:

  # start us out with the usual suspects
  use strict;
  use Perljax;
  use CGI;

  # define an anonymous perl subroutine that you want available to
  # javascript on the generated web page.

  my $evenodd_func = sub {
    my $input = shift;
    
    # see if input is defined
    if ( not defined $input ) {
      return("input not defined or NaN");
    }

    # see if value is a number (*thanks Randall!*)
    if ( $input !~ /\A\d+\z/ ) {
      return("input is NaN");
    }

    # got a number, so mod by 2
    $input % 2 == 0 ? return("EVEN") : return("ODD");

  }; # don't forget the trailing ';', since this is an anon subroutine

  # define a function to generate the web page - this can be done
  # million different ways, and can also be defined as an anonymous sub.
  # The only requirement is that the sub send back the html of the page.

  sub Show_HTML {
    my $html = <<EOT;

  <HTML>
  <HEAD><title>Perljax Example</title>
  </HEAD>
  <BODY>
    Enter a number:&nbsp;
    <input type="text" name="val1" id="val1" size="6"
       onkeyup="evenodd( ['val1'], 'resultdiv' );
       return true;"><br>
    <hr>
    <div id="resultdiv" style="border: 1px solid black;
          width: 440px; height: 80px; overflow: auto">
    </div>
  </BODY>
  </HTML>
  EOT

    return $html;
  }

  my $cgi = new CGI();  # create a new CGI object
  # now we create a Perljax object, and associate our anon code
  my $pjx = new Perljax( 'evenodd' => $evenodd_func );

  # now print the page.  This can be done easily using
  # Perljax->build_html, sending in the CGI object to generate the html
  # header.  This could also be done manually, and then you don't need
  # the build_html() method
  
  # this outputs the html for the page
  print $pjx->build_html($q,\&Show_Form);

  # that's it!

=head1 METHODS

=item build_html()

    Purpose: associate cgi obj ($q) with pjx object, insert
		         javascript into <HEAD></HEAD> element
  Arguments: either a coderef, or a string containing html
    Returns: html or updated html (including the header)
  Called By: originating cgi script

=cut

=item show_javascript()

    Purpose: builds the text of all the javascript that needs to be
             inserted into the calling scripts html header
  Arguments: 
    Returns: javascript text
  Called By: originating web script

=cut

=item show_common_js()

    Purpose: create text of the javascript needed to interface with
             the perl functions
  Arguments: none
    Returns: text of common javascript subroutine, 'do_http_request'
  Called By: originating cgi script, or build_html()

=cut

=head1 BUGS

=head1 SUPPORT

Check out the sourceforge discussion lists at:
  
  http://www.sourceforge.net/pjax

=head1 AUTHORS

	Brian C. Thomas     Brent Pedersen
	CPAN ID: BCT
	bct.x42@gmail.com   bpederse@gmail.com

=head1 COPYRIGHT

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=head1 SEE ALSO

Class::Accessor, CGI

=cut

############################################# main pod documentation end ##

######################################################
## METHODS - public                                 ##
######################################################


#=item build_html()
#
#    Purpose: associate cgi obj ($q) with pjx object, insert
#		         javascript into <HEAD></HEAD> element
#  Arguments: either a coderef, or a string containing html
#    Returns: html or updated html (including the header)
#  Called By: originating cgi script
#
#=cut

sub build_html {
  my ($self,$q,$html_source) = @_;
  if ( $self->DEBUG() ) {
    print STDERR "html_source is ", $html_source, "\n";
  }

	$self->cgi($q);  # associate the CGI object with this object
  #check if "fname" was defined in the CGI object
  if(defined $self->cgi()->param("fname")){
    # it was, so just return the html from the handled request
    return($self->handle_request());
	} else {
    my $html = $self->cgi()->header(); # start with the minimum,
                                       # a http header line
  
    # check if the user sent in a coderef for generating the html,
    # or the actual html 
    if( ref($html_source) eq "CODE"){
      eval { $html .= &$html_source };
      if ($@) {
        # there was a problem evaluating the html-generating function
        # that was sent in, so generate an error page
        $html = $self->cgi()->header();
        $html .= qq!<html><body><h2>Problems</h2> with 
          the html-generating function sent to Perljax
          object</body></html>!;
        return $html;
      }
      $self->html($html); # no problems, so set html
    } else {
      # user must have sent in raw html, so add it
      $self->html($html . $html_source);
    }
    # now modify the html to insert the javascript
    $self->insert_js_in_head(); 
  }
	return $self->html();
}

#=item show_javascript()
#
#    Purpose: builds the text of all the javascript that needs to be
#             inserted into the calling scripts html header
#  Arguments: 
#    Returns: javascript text
#  Called By: originating web script
#
#=cut

sub show_javascript {
  my ($self) = @_;
  my $rv = $self->show_common_js(); # first show the common js
;
  # now build the js for each perl function you want exported to js
  foreach my $func ( keys %{ $self->coderef_list() } ) {
    $rv .= $self->make_function( $func );
  }
  return $rv;
}

## new
sub new {
    my ($class) = shift;
    my $self = bless ({}, ref ($class) || $class);
    $self->mk_accessors( qw(coderef_list cgi html DEBUG JSDEBUG) );
		$self->JSDEBUG(0);
		$self->DEBUG(0);
    $self->{coderef_list} = {}; #accessorized
		$self->{html}=undef;
    $self->{cgi}= undef; #accessorized

    if ( @_ < 2 ) {
      die "incorrect usage: must have fn=>code pairs in new\n";
    }

    while ( @_ ) {
      my($function_name,$code) = splice( @_, 0, 2 );

      if ( $self->DEBUG() ) {
        print STDERR "name = $function_name, code = $code\n";
      }
      # add the name/code to hash
      $self->coderef_list()->{ $function_name } = $code;
    }
    return ($self);
} 
######################################################
## METHODS - private                                ##
######################################################

#=item show_common_js()
#
#    Purpose: create text of the javascript needed to interface with
#             the perl functions
#  Arguments: none
#    Returns: text of common javascript subroutine, 'do_http_request'
#  Called By: originating cgi script, or build_html()
#
#=cut

sub show_common_js {
  my $self = shift;

  my $rv = <<EOT;
function pjx(args,fname){
  this.dt=args[1];
  this.args=args[0]
  this.req=ghr();
  this.url = this.getURL(fname);
}

function getElem(id) {
  try {
    return document.getElementById(id).value.toString();
  } catch(e) {
    try { 
      return document.getElementById(id).innerHTML.toString();
    } catch(e) {
      if (id.constructor == Function ) {
        return id;
      }
      try {
        return document.getElementById(id).innerHTML.toString();
      } catch(e) {
        var errstr = 'ERROR: cant get html element with id:' +
        id + 'check that an element with id=' + id + ' exists';
        alert(errstr);return false;
      }
    }
  }
}

pjx.prototype.perl_do=function() {
  r = this.req;
  dt=this.dt;
  url=this.url;
//  document.getElementById('x').innerHTML = url;
  r.open("GET",url,true);
  r.onreadystatechange= function() {
    if ( r.readyState!= 4) { return; }
    var data = r.responseText;
    if (typeof(dt)=='string') {
      var div = document.getElementById(dt);
      if (div.type=='text') {
        div.value=data;
      } else {
        div.innerHTML = data;
      }
    } else if (typeof(dt)=='function') {
      dt(data.split('__pjx__'));
    }
  } // end handler
  r.send(null);
}

pjx.prototype.getURL=function(fname){
  args = this.args;
  url= window.location +'?fname=' + fname;
  for(i=0;i<args.length;i++){
    url=url + '&fnargs=' + escape(args[i]);
  }
  url = url.replace(/[+]/g,'%2B');
  return url;
}

function ghr() {
  if ( typeof ActiveXObject!="undefined" ) {
    try { return new ActiveXObject("Microsoft.XMLHTTP") }
    catch(a) { }
  }
  if ( typeof XMLHttpRequest!="undefined" ) {
    return new XMLHttpRequest();
  }
  return null;
}

EOT
  return $rv;
}

#=item insert_js_in_head()
#
#    Purpose: searches the html value in the Perljax object and inserts
#             the ajax javascript code in the <script></script> section,
#             or if no such section exists, then it creates it.
#  Arguments: none
#    Returns: none
#  Called By: build_html()
#
#=cut

sub insert_js_in_head{
  my $self = shift;
	my $mhtml = $self->html();
	my $newhtml;
	my @shtml;
	my $js = $self->show_javascript();
	if($self->JSDEBUG()){
	  my $showurl=qq|<br /><div id='__pjxrequest'></div><br/>|;
		my @splith = $mhtml =~ /(.*)(<\s*\/\s*body\s*>)(.*)/is;
		$mhtml = $splith[0].$showurl.$splith[1].$splith[2];
	}
  @shtml= $mhtml =~ /(.*)(<\s*\/\s*head\s*>)(.*)/is;
	if(@shtml){
    $newhtml = $shtml[0]."<script>".$js."</script>".$shtml[1].$shtml[2];
	} elsif( @shtml= $mhtml =~ /(.*)(<\s*html.*?>)(.*)/is){
    $newhtml = $shtml[0].$shtml[1]."<script>".$js."</script>".$shtml[2];
	}
	$self->html($newhtml);
	return;
}

#=item handle_request()
#
#    Purpose: makes sure a fname function name was set in the CGI
#             object, and then tries to eval the function with
#             parameters sent in on fnargs
#  Arguments: none
#    Returns: the result of the perl subroutine, as text; if multiple
#             arguments are sent back from the defined, exported perl
#             method, then join then with a connector (__pjx__).
#  Called By: build_html()
#
#=cut

sub handle_request {
  my ($self) = shift;
	
  my $rv = $self->cgi()->header();
  my $result; # $result takes the output of the function, if it's an
              # array split on __pjx__
  my @other = (); # array for catching extra parameters

  # make sure "fname" was set in the form from the web page
  return undef unless defined $self->cgi();	
  #return undef unless defined $self->cgi()->param("fname");

  # get the name of the function
  my $func_name = $self->cgi()->param("fname");

  # check if the function name was created
  if ( defined $self->coderef_list()->{$func_name} ) {
    my $code = $self->coderef_list()->{$func_name};
    
    # eval the code from the coderef, and append the output to $rv
    if ( ref($code) eq "CODE" ) {
      eval { ($result, @other) = $code->( $self->cgi()->param("fnargs") ) };

      if( @other ) {
          $rv .= join( "__pjx__", ($result, @other) );
          if ( $self->DEBUG() ) {
            print STDERR "rv = $rv\n";
          }
      } else {
        if ( defined $result ) {
          $rv .= $result;
        } 
      }

      if ($@) {
        # see if the eval caused and error and report it
        # Should we be more severe and die?
        if ( $self->DEBUG() ) {
          print STDERR "Problem with code: $@\n";
        }
      }
    } # end if ref = CODE
  } else {
    $rv .= "$func_name is not defined!";
  }
  return $rv;
}


#=item make_function()
#
#    Purpose: creates the javascript wrapper for the underlying perl
#             subroutine
#  Arguments: CGI object from web form, and the name of the perl
#             function to export to javascript
#    Returns: text of the javascript-wrapped perl subroutine
#  Called By: show_javascript; called once for each registered perl
#             subroutine
#
#=cut

sub make_function {
  my ($self, $func_name ) = @_;
  return("") if not defined $func_name;
  return("") if $func_name eq "";
  my $rv = "";
  my $jsdebug = $self->JSDEBUG();
  #create the javascript text
  $rv .= <<EOT;

function $func_name() {
  var args = $func_name.arguments;
  for( i=0; i<args[0].length;i++ ) {
    args[0][i] = getElem(args[0][i]);
  }
  var pjx_obj = new pjx(args,"$func_name");
  var tmp = '<a href= '+ pjx_obj.url +' target=_blank>' + pjx_obj.url +
	' </a>';
  pjx_obj.perl_do();
	if($jsdebug){
	  document.getElementById('__pjxrequest').innerHTML = tmp;
	}
}

EOT

 return $rv;
}

#=item Subroutine: register()
#
#    Purpose: adds a function name and a code ref to the global coderef hash
#  Arguments: function name, code reference
#    Returns: none
#  Called By: originating web script
#
#=cut

sub register {
  my ( $self, $fn, $coderef ) = @_;
  # coderef_list() is a Class::Accessor function
  $self->coderef_list()->{$fn} = $coderef;
}

1;
__END__
