#!/usr/bin/perl
#------------------------------------------------------------------------------
#  Дата: 14.09.2015 Автор: Николай Назаров
#  Описание: ajax скрипт, возвращает список привилегий для доплаты,
#  которые больше переданной суммы
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
my $discont = $cgi->param("user_sum");

my $html = "";
my $cfg = $m->{cfg};
my $dbh = $m->{dbh};
my ($id, $name, $type, $item, $amount, $extra, $server, $price, $html);
my $sth = $dbh->prepare ("SELECT `id`, `name`, `type`, `item`, `amount`, `extra`, `server`, `price` FROM `shop_cart_items` WHERE (`type`='permgroup') and (`price` > ?)  ORDER BY (`price`);") or die $!;
$sth -> execute ($discont);
$sth -> bind_columns (\$id, \$name, \$type, \$item, \$amount, \$extra, \$server, \$price);
while ($sth -> fetch ()) {
    my $donateTime = $m->donateTime($item);
    $html .= qq {
            <option value="$id">$name - $price руб. [$donateTime]</option>
    };
}

print "Content-type: text/html\n\n";
print $html;