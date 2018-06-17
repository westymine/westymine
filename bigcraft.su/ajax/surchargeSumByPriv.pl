#!/usr/bin/perl
#------------------------------------------------------------------------------
#  Дата: 14.09.2015 Автор: Николай Назаров
#  Описание: ajax скрипт, возвращает стоимость указанной привилегии по Id
#------------------------------------------------------------------------------

use strict;
use warnings;
use CGI::Carp qw(fatalsToBrowser);
use lib '..';
use DonateCMS;

#------------------------------------------------------------------------------

# Init
my $m = DonateCMS->new();
my $cgi = $m->{cgi};
my $id = $cgi->param("privelege");
my $sum = $m->dbGet("SELECT `price` FROM `shop_cart_items` WHERE (`id` = ?)", $id);

print "Content-type: text/html\n\n";
print $sum;