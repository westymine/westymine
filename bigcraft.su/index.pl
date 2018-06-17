#!/usr/bin/perl
#------------------------------------------------------------------------------
#    PerlCMS - движок для управления контентом
#    Copyright (c) 20015 Назаров Николай
#------------------------------------------------------------------------------


use strict;
use warnings;
use CGI::Carp qw(fatalsToBrowser);
use DonateCMS;

#------------------------------------------------------------------------------

# Init
my $m = DonateCMS->new();
my $cgi = $m->{cgi};
my $cfg = $m->{cfg};

if ($cgi->param("go") ne "") {
    $cfg->{templateDefault} = $cgi->param("go") . ".html";
    $m->templateLoad();
    $m->templateParse();
}

print "Content-type: text/html\n\n";
print $m->{template};