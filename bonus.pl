#!/usr/bin/perl
#------------------------------------------------------------------------------
#  Дата: 14.09.2015 Автор: Николай Назаров
#  Описание: скрипт для выдачи призов за голосование на сайте
#    http://monitoringminecraft.ru
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

my $secretKey = $cfg->{monitoringminecraftSecretKey};

my $player = $cgi->param('username');
my $ip = $cgi->param('ip');
my $timestamp = $cgi->param('timestamp');
my $signature = $cgi->param('signature');

if ( ! $player || ! $ip || ! $timestamp || ! $signature) {
    &error("присланы не все данные");
}

use Digest::SHA 'sha1_hex';
my $check_signature = sha1_hex($player.$timestamp.$secretKey);

if ($check_signature != $signature) {
    &error("неверная подпись / секретный ключ");
}

$m->dbDo("INSERT INTO `shop_cart` (`player`, `type`, `item`, `amount`, `server`) VALUES (?, 'permgroup', ?, 1, 1)", $player, $cfg->{monitoringminecraftPrize1});

print "content-type: text/html\n\n";
print "ok, monitoring\n";


sub error ()
{
    my ($error) = @_;
    print $cgi->header (-type => 'text/html', -charset => 'utf-8', -status=>'500 Server Error');
    die $error;
}