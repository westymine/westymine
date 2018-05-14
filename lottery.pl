#!/usr/bin/perl
#------------------------------------------------------------------------------
#    Lottery - модуль для проведения лотерей
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
my $env = $m->{env};

my $url = $cfg->{baseUrl};
my $event = $cgi->param("event");
my $ip = $env->{userIp};
my $player = $cgi->param("player");
my $lotteryMaxPlayers =  $cfg->{lotteryMaxPlayers};

my $debug = 0;
#print $cgi->header(-charset=>'utf-8');

if ( $event == 1) {
    if ($player eq '') {
        $m->logDebug("Введите Никнейм") if ($debug == 1);
        print $cgi->redirect("$url/?go=lottery&error=lotteryPlayerVoid");
        exit;
    }
    if ($cfg->{lotteryCheckRegistration}) {
        if (! $m->checkPlayerRegistration($player)) {
            $m->logDebug("Игрок не зарегистрирован") if ($debug == 1);
            print $cgi->redirect("$url/?go=lottery&error=lotteryPlayerNotRegistered");
            exit;
        }
    }
    if ($m->checkPlayer($player)) {
       if ($m->checkIP($ip)) {
           if ($m->countWinners() > 0) {
               $m->logDebug("Сегодня конкурс завершен, попробуйте испытать удачу завтра") if ($debug == 1);
               print $cgi->redirect("$url/?go=lottery&error=lotteryCompleted");
               exit;
           }
           else {
               if ($m->checkWinner($player) > 0 ) {
                   $m->logDebug("Вы недавно побеждали в конкурсе, попробуйте позже") if ($debug == 1);
                   print $cgi->redirect("$url/?go=lottery&error=lotteryYouAreTheWinner&days=" . $m->checkWinner($player) );
                   exit;
               }
               $m->addPlayers ($player, $ip);
               my $count = $m->countPlayers ();
               $m->logDebug("Количество участников $count, Максимальное количество игроков $lotteryMaxPlayers") if ($debug == 1);
               if ($count >= $lotteryMaxPlayers) {
                   $m->logDebug("Выбираем победителей.") if ($debug == 1);
                   $m->addWinner ();
               }
               print $cgi->redirect("$url?go=lottery");
               exit;
               # print  $m->showPlayers ();
               # print  $m->showWinners ();
          }
       }
       else {
           $m->logDebug("С вашего IP-адреса уже была подана заявка на участие в конкурсе") if ($debug == 1);
           print $cgi->redirect("$url/?go=lottery&error=lotteryLimitIP");
           exit;
       }
    }
    else {
        $m->logDebug("Пользователь с ником $player уже участвует в конкурсе") if ($debug == 1);
        print $cgi->redirect("$url/?go=lottery&error=lotteryPlayerExists");
        exit;
    }
} else {
   $m->logDebug("Не задан event") if ($debug == 1);
}

