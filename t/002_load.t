# -*- perl -*-

# t/002_load.t - check module loading and create testing directory

use Test::More tests => 2;

BEGIN { use_ok( 'CGI::Perljax' ); }

my $object = CGI::Perljax->new ( 'myfunc' => '');
isa_ok ($object, 'CGI::Perljax');
