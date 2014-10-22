#! /usr/bin/perl -w

# this is an example of using subs (not coderefs) for your perljax
# functions
#
# NB The Perljax object DOES NOT need to follow the function
# declarations, as it does in the coderef example

use strict;
use CGI::Perljax;
use CGI;

my $q = new CGI;
my $pjx = CGI::Perljax->new( 'myfunc' => \&exported_fx);
print $pjx->build_html($q,\&Show_Form); # this outputs the html for the page

sub exported_fx {
  my $value_a = shift;
  my $value_b = shift;
  $value_a = "" if not defined $value_a; # make sure there's def
  $value_b = "" if not defined $value_b; # make sure there's def

  if ( $value_a =~ /\D+/ or $value_a eq "" ) {
    return( $value_a . " and " . $value_b );
  } elsif ( $value_b =~ /\D+/ or $value_b eq "" ) {
    return( $value_a . " and " . $value_b );
  } else {
    # got two numbers, so lets multiply them together
    return( $value_a * $value_b );
  }
}

sub Show_Form {
  my $html = "";
  $html .= <<EOT;
<HTML>
<HEAD><title>Perljax Example</title>
</HEAD>
<BODY>
  Enter something:&nbsp;
  <input type="text" name="val1" id="val1" size="6" onkeyup="myfunc( ['val1','val2'], 'resultdiv' ); return true;"><br>

  Enter something else:&nbsp;
  <input type="text" name="val2" id="val2" size="6" onkeyup="myfunc( ['val1','val2'], 'resultdiv' ); return true;"><br>

    <hr>
    <div id="resultdiv" style="border: 1px solid black; width: 440px; height: 80px; overflow: auto">
    </div>
</BODY>
</HTML>
EOT
  return $html;
}
