#!/usr/bin/perl
#------------------------------------------------------------------------------
#    PerlCMS - движок для управления контентом
#    Copyright (c) 20015 Назаров Николай
#------------------------------------------------------------------------------


use strict;
use warnings;
use CGI::Carp qw(fatalsToBrowser);
use CGI::Cookie;
use Digest::SHA qw(sha256_hex);
use DonateCMS;

#------------------------------------------------------------------------------

# Init
my $m = DonateCMS->new();
my $cgi = $m->{cgi};
my $cfg = $m->{cfg};
my $action = $cgi->param('action');

my $fingerprint = 'trololo';

my %cookies = fetch CGI::Cookie;
if ($cookies{fingerprint}) {
    $fingerprint = $cookies{fingerprint}->value;
}

if ($action eq 'logout') {
    $fingerprint = 'trololo';
}

if (($action eq 'auth')
   and ($cgi->param('login') eq $cfg->{cpUser})
   and ($cgi->param('password') eq $cfg->{cpPassword})) {
   $fingerprint = sha256_hex($cfg->{cpUser} . $cfg->{cpPassword});
}

my $cookie = new CGI::Cookie(-name=>'fingerprint', -value=>$fingerprint, -expires=>'1d');



if (sha256_hex($cfg->{cpUser} . $cfg->{cpPassword}) ne $fingerprint) {
    print $cgi->header (-charset=>'utf-8', -cookie=>$cookie);
    print qq{<!DOCTYPE html>
<html lang="ru">
<head>
<meta charset="utf-8">
<meta http-equiv="X-UA-Compatible" content="IE=edge">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Панель управления</title>
<link rel="stylesheet" href="https://maxcdn.bootstrapcdn.com/font-awesome/4.3.0/css/font-awesome.min.css">
<link rel="stylesheet" href="https://maxcdn.bootstrapcdn.com/bootstrap/3.3.2/css/bootstrap.min.css">
<link rel="stylesheet" href="https://maxcdn.bootstrapcdn.com/bootstrap/3.3.2/css/bootstrap-theme.min.css">
<!--[if lt IE 9]>
    <script src="https://oss.maxcdn.com/html5shiv/3.7.2/html5shiv.min.js"></script>
    <script src="https://oss.maxcdn.com/respond/1.4.2/respond.min.js"></script>
<![endif]-->
<style>
    .space-small \{height: 32px;\}
</style>
</head>

<body>
    <div class="container text-center">
        <div class="row">
            <div class="space-small"></div>
            <div class="col-md-6 col-md-offset-3">
                <div class="well bs-component">
                    <form action="/admin.pl" method="post" class="form-horizontal">
                        <fieldset>
                            <legend>Авторизация</legend>
                            <div class="form-group">
                                <input type="text" name="login" class="form-control" required="" placeholder="Логин">
                            </div>
                            <div class="form-group">
                                <input type="password" name="password" class="form-control" required="" placeholder="Пароль">
                            </div>
                            <div class="form-group">
                                <button type="submit" class="btn btn-lg btn-danger"><i class="fa fa-sign-in"></i> Войти</button>
                            </div>
                            <input type="hidden" name="action" value="auth">
                        </fieldset>
                    </form>
                </div>
            </div>
        </div>
    </div>

</body>
</html>
    };
    exit;
}


if ($action eq "additems") {
    $m->adminDonateInsert();
    print "Content-type: text/html\n\n";
    print "Данные добавлены";
    exit;
}
elsif ($action eq "delitem") {
    $m->adminDonateDelete();
    print "Content-type: text/html\n\n";
    print "Данные удалены";
    exit;
}
elsif ($action eq "itemUpdate") {
    $m->adminDonateUpdate();
    print "Content-type: text/html\n\n";
    print "Данные обновлены";
    exit;
}

print $cgi->header (-charset=>'utf-8', -cookie=>$cookie);
my $donateList = $m->adminDonateList();


print qq{<!DOCTYPE html>
<html lang="ru">
<head>
<meta charset="utf-8">
<meta http-equiv="X-UA-Compatible" content="IE=edge">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Панель управления</title>
<link rel="stylesheet" href="https://maxcdn.bootstrapcdn.com/font-awesome/4.3.0/css/font-awesome.min.css">
<link rel="stylesheet" href="https://maxcdn.bootstrapcdn.com/bootstrap/3.3.2/css/bootstrap.min.css">
<link rel="stylesheet" href="https://maxcdn.bootstrapcdn.com/bootstrap/3.3.2/css/bootstrap-theme.min.css">
<!--[if lt IE 9]>
    <script src="https://oss.maxcdn.com/html5shiv/3.7.2/html5shiv.min.js"></script>
    <script src="https://oss.maxcdn.com/respond/1.4.2/respond.min.js"></script>
<![endif]-->
<style>
    .space-small \{height: 32px;\}
</style>
</head>

<body>
    <div class="navbar navbar-static-top">
            <div class="container">
                <div class="navbar-header">
                    <a class="navbar-brand" href="https://vk.com/dagcity777" target="_blank">Майнкрафт Донат<sup style="color: #FF34B3;">[beta]</sup></a>

                    <button type="button" class="navbar-toggle collapsed" data-toggle="collapse" data-target="#navbar" aria-expanded="false" aria-controls="navbar">
                        <span class="sr-only">Toggle navigation</span>
                        <span class="icon-bar"></span>
                        <span class="icon-bar"></span>
                        <span class="icon-bar"></span>
                    </button>
                </div>
                <ul class="nav navbar-nav" id="navbar" class="collapse navbar-collapse">
                    <li class="active"><a href="#">Панель управления</a></li>
                    <li class="dropdown">
                        <a href="" class="dropdown-toggle" data-toggle="dropdown" role="button" aria-expanded="true"><i class="fa fa-life-ring"></i> Техподдержка <span class="caret"></span></a>
                        <ul class="dropdown-menu" role="menu">
                            <li><a href="skype:predator_pbh?chat"><i class="fa fa-skype"></i> Скайп</a></li>
                            <li><a href="">Почта</a></li>
                            <li><a href="https://vk.com/dagcity777">Сайт</a></li>
                            <!--li class="divider"></li-->
                        </ul>
                    </li>
                </ul>
                <ul class="nav navbar-nav pull-right" id="logout">
                    <li><a href="/cpanel/logout/"><i class="fa fa-sign-out"></i> Выход</a></li>
                </ul>
            </div>
    </div>

    <div class="container">
        <div class="row">
            <div class="col-md-8">
                <h3>Панель Управления Донатом</h3>

                $donateList

                <hr id="hr" />
                <div class="space-small"></div>
                <div class="row">
                    <div class="col-md-6">
                        <button class="btn btn-lg btn-danger" onclick="tool.addItemForm(this)">Добавить</button>
                    </div>
                    <div class="col-md-6">
                        <button class="btn btn-lg btn-danger" onclick="tool.addItems()">Сохранить</button>
                    </div>
                </div>
                <div class="space-small"></div>
            </div>
        </div>
    </div>

    <div class="container">
        <div class="row">
        
        </div>
    </div>
<script src="https://ajax.googleapis.com/ajax/libs/jquery/1.11.2/jquery.min.js"></script>
<script src="https://maxcdn.bootstrapcdn.com/bootstrap/3.3.2/js/bootstrap.min.js"></script>
<script src="/admin/tools.js"></script>

        

</body>
</html>
};