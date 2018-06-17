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

my $dbh = $m->{dbh};

open IMPORT, "donate.csv";

while (<IMPORT>) {
    chomp;
    my ($date, $item, $type, $player, $price) = split ";", $_;
    my ($datePart1, $datePart2) = split " ", $date;
    my ($day, $month, $year) = split "-", $datePart1;
    $date = "$year-$month-$day $datePart2";
    $m->dbDo("INSERT INTO `shop_cart_transactions` (`date`,`player`,`type`,`item`,`amount`,`server`,`price`) VALUES (?,?,'permgroup',?,1,1,?)", $date, $player, $item, $price);
}

close IMPORT;