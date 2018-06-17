#!/usr/bin/perl
#------------------------------------------------------------------------------
#    PerlCMS - движок для управления контентом
#    Copyright (c) 20015 Назаров Николай
#------------------------------------------------------------------------------


use strict;
use warnings;
use CGI::Carp qw(fatalsToBrowser);
use CGI::Cookie;
#use Digest::SHA qw(sha256_hex);
use DonateCMS; 

#------------------------------------------------------------------------------
# Init

my $m = DonateCMS->new();
my $cgi = $m->{cgi};
my $cfg = $m->{cfg};
my $url = $cfg->{baseUrl};
my $donatePlayer = $cgi->param('donatePlayer');
my $donateItem = $cgi->param('donateItem');
my $payment = $cfg->{payment};

#------------------------------------------------------------------------------
# Редиректим на сайт платежной системы

if (("$donatePlayer" ne "") and ("$donateItem" ne "")) {

    my ($donateDescription, $donateSum);
    if ($donateItem eq "donaterecover") {
        $donateDescription = qq{Восстановление привилегий для игрока $donatePlayer};
        $donateSum = $m->donateRecoverSum ($donatePlayer);
        $donateSum ||= 1;
    }
    if ($donateItem =~ /donatecase(\d+)/) {
        $donateDescription = qq{Покупка Кейсы $1 шт для игрока $donatePlayer};
        $donateSum = $cfg->{$donateItem};
    }
    elsif ($donateItem eq "unban") {
        if ($m->donateCheckBan($donatePlayer)) {
            $donateDescription = qq{Покупка разбана для игрока $donatePlayer};
            $donateSum = $cfg->{unbanPrice};
        }
        else {
            print $cgi->redirect(-url=>qq{$url/?errorPay=playerIsNotBanned});
        }
    }
    else {
        $donateDescription = $m->donateDescription ($donateItem, $donatePlayer);
        $donateSum = $m->donateSum($donateItem, $donatePlayer);
    }
    if ($payment eq "unitpay") {
        print $cgi->redirect(-url=>qq{https://unitpay.ru/pay/$cfg->{unitpayPublicKey}?account=$donateItem|$donatePlayer&desc=$donateDescription&sum=$donateSum});
    }
    exit;
}


if ($payment eq "unitpay") {
    $m->unitpayInitParams();
    if ($cgi->param("params[sign]") ne $m->unitpayMd5Sign()) {
        $m->unitpayResponseError("Некорректная цифровая подпись");
    }
    if ($cgi->param("method") eq "check") { $m->unitpayCheck(); }
    if ($cgi->param("method") eq "pay")   { $m->unitpayPay(); }
    if ($cgi->param("method") eq "error") { $m->unitpayError(); }
}
else {
    #нет подходящего метода.
}

