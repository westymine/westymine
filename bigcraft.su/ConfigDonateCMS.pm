package ConfigDonateCMS;
use strict;
use warnings;
our ($VERSION, $cfg);
$VERSION = "1.0.2";

#-----------------------------------------------------------------------------
# Базовые настройки

$cfg->{projectName}       = "BigCraft"; # Название проекта
$cfg->{baseUrl}           = "http://bigcraft.su/"; # Адрес сайта, например,
$cfg->{adminEmail}        = ""; # Адрес электронной почты администратора сервера
$cfg->{adminSkype}        = ""; # Скайп Администратора сервера
$cfg->{adminVK}           = "http://vk.com/topsexsex"; # ВК администратора сервера (ссылка)
$cfg->{dateOfCreation}     = "15.12.2016"; #дата создания проекта

$cfg->{serverIp}          = "mc.bigserv.ru"; # IP-адрес вашего сервера Майнкрафт
$cfg->{serverPort}        = "25565"; # Порт вашего сервера Майнкрафт

$cfg->{dbServer}          = "localhost"; # Адрес сервера MySQL, например, localhost 
$cfg->{dbName}            = "loadcore"; # Название базы данных MySQL
$cfg->{dbUser}            = "loadcore"; # Имя пользователя базы данных MySQL
$cfg->{dbPassword}        = ""; # Пароль от базы данных MySQL
$cfg->{cpUser}            = ""; # Логин от панели управления доступна по адресу http://адрес.сайта/cpanel/
$cfg->{cpPassword}        = ""; # Пароль от панели управления
$cfg->{templatePath}      = "template/bigcraft"; # Название шаблона сайта, хранится в папке template
$cfg->{templateDefault}   = "index.html"; # Файл шаблона по умолчанию
$cfg->{sendmail}          = "/usr/sbin/sendmail -t";

$cfg->{unbanPrice}             = 100; # продажа разбана игрока
$cfg->{surcharge}              = 1;  # доплата доната
$cfg->{enableOnlineMaxRecord}  = 1;  # включить вывод статистики сервера
$cfg->{enableDonateRecover}    = 0; # включить возможность восстановления доната 0 - выключено, любое другое число % от стоимости восстановления
$cfg->{enableDonateOptGroup}   = 1;  # выводить донат по группам

#-----------------------------------------------------------------------------
# Покупка кейсов

$cfg->{enableCases}            = 1; #1 - включить кейсы, 2 выключить кейсы
$cfg->{donatecase1}           = 30; # 10 кейсов за 150р
$cfg->{donatecase5}           = 120; # 10 кейсов за 150р
$cfg->{donatecase10}           = 220; # 10 кейсов за 150р


#-----------------------------------------------------------------------------
# Платежная система

$cfg->{payment}           = "unitpay"; # Варианты $cfg->{payment} --> waytopay или unitpay
$cfg->{unitpayPublicKey}  = "14437-29a70"; # Заполнять, если $cfg->{payment} == unitpay
$cfg->{unitpaySecretKey}  = "4b6bb135b9f2aa4375192242a2ca2c4c"; # Заполнять, если $cfg->{payment} == unitpay
$cfg->{waytopayId}        = ""; # Заполнять, если $cfg->{payment} == waytopay
$cfg->{waytopaySecretKey} = ""; # Заполнять, если $cfg->{payment} == waytopay

#-----------------------------------------------------------------------------
# Настройки Лотереи

$cfg->{lotteryMaxPlayers}  = 500; # максимальное количество игроков лотерии
$cfg->{lotteryMaxIP}       = 1;  # сколько раз можно играть с одного IP-адреса
$cfg->{lotteryMaxWinners}  = 1;  # Максимальное количество победителей
$cfg->{lotteryShowWinners} = 3;  # Сколько последних победителей отображать в таблице с результатами
$cfg->{lotteryCheckRegistration} = 1;
$cfg->{lotteryWin1}        = "prefix_lucky?lifetime=604800"; # ?lifetime=2592000 - 30 дней, ?lifetime=259200 - 3 дня, ?lifetime=604800 - 7 дней
$cfg->{lotteryWin2}        = "creat?lifetime=2592000";
$cfg->{lotteryWin3}        = "vip?lifetime=2592000";

#-----------------------------------------------------------------------------
# Параметры нужны для совместимости, НЕ РЕДАКТИРОВАТЬ
$cfg->{monitoringIp}       = $cfg->{serverIp};      
$cfg->{monitoringPort}     = $cfg->{serverPort};

#-----------------------------------------------------------------------------
# Заголовки типов доната для форм оплаты

$cfg->{donateType}        = {
    "permgroup" => "Покупка привилегии",
    "perm"      => "Покупка команды",
    "money"     => "Игровая валюта",
    "item"      => "Покупка предметов и блоков",
    "rgown"     => "Покупка привата",
};

$cfg->{donateForm}        = qq{
    <div class="row">
        <div class="col-md-12 text-center">
            <h2>\{\{formHeader\}\}</h2>
        </div> 
        <div class="col-md-6 col-md-offset-3 text-center">
            <div class="well bs-component">
                <form class="form-horizontal" action="/payment.pl">
                    <fieldset>
                        <legend>После оплаты, зайдите на сервер и напишите в чате <code>/cart all</code></legend>
                        <div class="form-group"><div class="alert alert-error" id="error"></div></div>
                        <div class="form-group" style="margin-left: 15px; margin-right: 15px;">
                            <input type="text" name="donatePlayer" class="form-control" required="" placeholder="Ник на сервере">
                        </div>
                        <div class="form-group" style="margin-left: 15px; margin-right: 15px;">
                            <select name="donateItem" class="form-control">\{\{donateList\}\}</select>
                        </div>
                        <div class="form-group"><button type="submit" class="btn btn-danger btn-lg" style="width: 50%;">Купить</button></div>
                    </fieldset>
                </form>
            </div>
        </div>
        <div class="col-md-12" style="height: 50px;"></div>
    </div>
};


#-----------------------------------------------------------------------------
# Дополнительные настройки
#-----------------------------------------------------------------------------

$cfg->{serverVK} = qq{http://vk.com/minecraft_bigcraft};


$cfg->{yandexCounter}     = qq{



};



#-----------------------------------------------------------------------------
# Всё хорошо!

1;
