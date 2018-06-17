#!/usr/bin/perl
#------------------------------------------------------------------------------
#  Дата: 14.09.2015 Автор: Николай Назаров
#  Описание: ajax скрипт, возвращает сумму покупок привилегий по Никнейму
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
my $donatePlayer = $cgi->param("name");
my $discont = $m->dbGet("SELECT SUM(`price`) FROM `shop_cart_transactions` WHERE (`type` = 'permgroup') and (LOWER(`player`) = LOWER(?))", $donatePlayer);

print "Content-type: text/html\n\n";
print $discont if ($discont != 0);