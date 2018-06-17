#------------------------------------------------------------------------------
#    
#    (c) 2011-2015 Назаров Николай
#
#        Skype: Nazarov.Nikolay 
#        Email: Nazarov.Nikolay@shonado.ru  
# 
#------------------------------------------------------------------------------

package DonateCMS;
use 5.008001;
use strict;
use warnings;
no warnings qw(uninitialized redefine once);
our $VERSION = "1.0.2";


sub new
{
    my $class = shift ();
    my %params = @_;

    my $m = {
        cfg => undef,
        dbh => undef,
        cgi => undef,
        now => time(),
        env => {},
        user => undef,
        template => undef,
        unitpay => 0,
        waytopay => 0,
        pageId => 0,
        templateParse => {},
        unitpayParams => {},
        waytopayParams => {},
    };
    bless $m, $class;

    $m->initEnvironment();
    $m->initCGI();


    $m->initConfiguration();
    my $cfg = $m->{cfg};

    $m->dbConnect();

    $m->serverOnline();

    $m->templateLoad();
    $m->templateParse();


    return $m;
}

sub initCGI ()
{
    my $m = shift();
    require CGI;
    $m->{cgi} = new CGI;
}

sub initEnvironment ()
{
    my $m = shift ();
    my $env = $m -> {env};
    $env->{documentRoot} = $ENV{DOCUMENT_ROOT};
    $env->{port} = $ENV{SERVER_PORT};
    $env->{method} = $ENV{REQUEST_METHOD};
    $env->{requestUri} = $ENV{REQUEST_URI};
    $env->{protocol} = $ENV{SERVER_PROTOCOL};
    $env->{host} = $ENV{HTTP_HOST};
    $env->{host} =~ s!:\d+\z!!;
    $env->{realHost} = $ENV{HTTP_X_FORWARDED_HOST} || $ENV{HTTP_X_HOST} || $env->{host};
    ($env->{script}) = $ENV{SCRIPT_NAME} =~ m!.*/(.*)\.!;
    ($env->{scriptUrlPath}) = $ENV{SCRIPT_NAME} =~ m!(.*)/!;
    $env->{cookie} = $ENV{HTTP_COOKIE} || $ENV{COOKIE};
    $env->{referrer} = $ENV{HTTP_REFERER};
    $env->{accept} = lc($ENV{HTTP_ACCEPT});
    $env->{acceptLang} = lc($ENV{HTTP_ACCEPT_LANGUAGE});
    $env->{userAgent} = $ENV{HTTP_USER_AGENT};
    $env->{userIp} = lc($ENV{REMOTE_ADDR});
    $env->{userAuth} = $ENV{REMOTE_USER};
    $env->{params} = $ENV{QUERY_STRING};
    $env->{https} = $ENV{HTTPS} eq 'on' || $env->{port} == 443;
    $env->{host} = "[$env->{host}]" if index($env->{host}, ":") > -1;
    ($m->{uaLangCode}) = $m->{env}{acceptLang} =~ /^([A-Za-z]{2})/;
}

sub initConfiguration ()
{
    my $m = shift();
    my $module = "ConfigDonateCMS";
    eval { require "$module.pm" };
    !$@ or die "Не могу загрузить файл настроек ConfigDonateCMS.pm. ($@)";
    eval "\$m->{cfg} = \$${module}::cfg";
    !$@ or die "Configuration assignment failed. ($@)";
}

###############################################################################
# Получаем online сервера

sub serverOnline ()
{
    my $m = shift();
    my $cfg = $m->{cfg};
    if (($cfg->{enableOnlineMaxRecord}) and ($cfg->{monitoringIp} ne "")) {
        use LWP::Simple qw($ua get);
        $ua->timeout(2);
        ($m->{playersOnline}, $m->{playersMax}, $m->{playersRecord}) = split /\//, get("http://worldedit.shonado.ru/ajax/minecraft_monitoring.pl?param=1:$cfg->{monitoringIp}:$cfg->{monitoringPort}") || ("???/???/???");
    }
}

###############################################################################
# Сколько дней проекту

sub projectDays ()
{
    my $m = shift();
    my $cfg = $m->{cfg};
    my ($mday, $mon, $year) = split /\./, $cfg->{dateOfCreation};
    if (($mday ne "") and ($mon ne "") and ($year ne "")) {
        #timelocal($sec, $min, $hours, $mday, $mon, $year);
        use Time::Local;
        return int ((time - timelocal(0, 0, 0, $mday, $mon-1, $year)) / 86400);
    }
    return 0;
}


###############################################################################
# Розыгрыш привилегий Lottery

sub checkWinner()
{
    my $m = shift();
    my ($player) = @_;
    my $days = $m->dbGet("SELECT TO_DAYS(NOW()) - TO_DAYS(`date`) AS `days` FROM `lottery` WHERE (`player` = ?) AND (`win` = 1) ORDER BY `date` DESC", $player);
    $days = 31 if ($days eq "");
    return 30 - $days if ($days < 7);
    return 0;
}

sub checkPlayer()
{
    my $m = shift();
    my ($player) = @_;
    my $count = $m->dbGet("SELECT COUNT(*) AS `count` FROM `lottery` WHERE (LOWER(`player`)=LOWER(?)) AND (`date` = DATE(NOW()))", $player);
    return 1 if ($count == 0);
    return 0;
}

sub checkPlayerRegistration()
{
    my $m = shift();
    my ($player) = @_;
    my $count = $m->dbGet("SELECT COUNT(*) AS `count` FROM `authme` WHERE (LOWER(`username`)=LOWER(?))", $player);
    return $count;
}

sub checkIP()
{
    my $m = shift();
    my ($ip) = @_;
    my $cfg = $m->{cfg};
    my $count = $m->dbGet("SELECT COUNT(*) AS `count` FROM `lottery` WHERE (`ip`=?) AND (`date` = DATE(NOW()))", $ip);
    $count ||= 0;
    return 1 if ($count < $cfg->{lotteryMaxIP});
    return 0;
}

sub countWinners()
{
    my $m = shift();
    return $m->dbGet("SELECT COUNT(*) AS `count` FROM `lottery` WHERE (`date` = DATE(NOW())) AND (`win` <> 0)");
}

sub addPlayers ()
{
    my $m = shift();
    my ($player, $ip) = @_;
    $m->dbDo("INSERT INTO `lottery` (`player`, `ip`, `date`) VALUES (?, ?, NOW())", $player, $ip);
}

sub countPlayers ()
{
    my $m = shift();
    return $m->dbGet("SELECT COUNT(*) AS `count` FROM `lottery` WHERE (`date` = DATE(NOW()))");
}

sub showPlayers ()
{
    my $m = shift;
    my ($i, $html, $date, $player) = (1);
    my $dbh = $m->{dbh};
    my $cfg = $m->{cfg};
    my $sth = $dbh->prepare("SELECT `date`, `player` FROM `lottery` WHERE (`date` = DATE(NOW())) ORDER BY (`id`) DESC");
    $sth -> execute ();
    $sth -> bind_columns (\$date, \$player);
    while ($sth -> fetch()) {
        $html .= qq{<tr><td class='text-left'>$i</td><td class='text-left'>$date</td><td class='text-left'> <img src='$cfg->{baseUrl}/playerHead.pl?player=$player&size=16' /> $player</td></tr>};
        $i++;
    }
    $sth -> finish();
    return qq{<table class='table table-striped table-hover '><thead><tr><th>N</th><th>Дата</th><th>Никнейм</th></tr><tbody>$html</tbody></table>};
}

sub showWinnersToday ()
{
    my $m = shift();
    my $cfg = $m->{cfg};
    my $html = '';
    my $countWinners = $m->countWinners();
    if ($countWinners == 0) {
        my $needPlayers = $cfg->{lotteryMaxPlayers} - $m->countPlayers ();
        $html = qq{
            <strong>Розыгрыш привелегий</strong> еще не завершен. Не хвататет игроков ($needPlayers чел).
            Если вы хотите выиграть привилегию пройдите по ссылке <a href='$cfg->{baseUrl}/?go=lottery' target='_blank' class='alert-link'>$cfg->{baseUrl}/#lottery</a>.
        };
    }
    else {
        my ($i, $date, $player, $win, @class) = (0, '', '', '', "label-info", "label-success", "label-danger");
        my $dbh = $m->{dbh};
        my $sth = $dbh -> prepare ("SELECT `date`, `player`, `win` FROM `lottery` WHERE (`win` <> 0) AND (`date` = DATE(NOW())) ORDER BY (`date`) DESC, (`win`) ASC;");
        $sth -> execute ();
        $sth -> bind_columns (\$date, \$player, \$win);
        while ($sth -> fetch()) {
            $html .= qq{<span class='label $class[$i]'><img src='$cfg->{baseUrl}/playerHead.pl?player=$player&size=16' /> $player ($win место)</span>};
            $i++;
        }
        $sth -> finish ();
        $html = qq{<strong>Победители сегодня</strong>: <br/>$html};
    }
}

sub showWinners ()
{
    my $m = shift();
    my ($i, $html, $date, $player, $win, @class) = (0, '', '', '', '', "info", "success", "danger");
    my $dbh = $m->{dbh};
    my $cfg = $m->{cfg};
    my $count = $cfg->{lotteryShowWinners};
    $count ||= 3;
    my $sth = $dbh->prepare("SELECT `date`, `player`, `win` FROM `lottery` WHERE (`win` <> 0) ORDER BY (`date`) DESC, (`win`) ASC LIMIT 0, $count;") or die $!;
    $sth -> execute ();
    $sth -> bind_columns (\$date, \$player, \$win);
    while ($sth->fetch()) {
        $html .= qq{<tr class='$class[$i++]'><td class='text-left'>$date</td><td class='text-left'> <img src="$cfg->{baseUrl}/playerHead.pl?player=$player&size=16" /> $player ($win место)</td></tr>};
    }
    return qq{<table class='table table-striped table-hover '><thead><tr><th>Дата</th><th>Никнейм</th></tr></thead><tbody>$html</tbody></table>};
}

sub addWinner ()
{
    my $m = shift();
    my $cfg = $m->{cfg};
    my $dbh = $m->{dbh};
    my $sth = $dbh->prepare("SELECT `player` FROM `lottery` WHERE (`date` = DATE(NOW())) AND (`win` = 0)");
    $sth->execute();
    my (@players, @winners, $row);
    while ($row = $sth->fetchrow_arrayref()) {
        push @players, $row->[0]; 
    }
    for(1..$cfg->{lotteryMaxWinners}){
        my $i = rand(@players);
        $winners[$_] = $players[$i];
        delete $players[$i];
    }
    for (1..$cfg->{lotteryMaxWinners}) {
        $m->dbDo("INSERT INTO `shop_cart` (`player`, `type`, `item`, `amount`, `server`) VALUES (?, 'permgroup', ?, 1, 1)", $winners[$_], $cfg->{"lotteryWin$_"});
        $m->dbDo("UPDATE `lottery` SET `win`=? WHERE (`date` = DATE(NOW())) AND (`player` = ?)", $_, $winners[$_]);
    }
}

sub lotteryErrors ()
{
    my $m = shift();
    my $cgi = $m->{cgi};
    my $error = $cgi->param("error");
    my $days = $cgi->param("days");
    my %errors = (
        "lotteryPlayerNotRegistered" => "Этот игрок ни разу не играл на нашем сервере :-/",
        "lotteryPlayerVoid" => "Введите Никнейм",
        "lotteryCompleted" => "Сегодня конкурс завершен, попробуйте испытать удачу завтра",
        "lotteryLimitIP" => "С вашего IP-адреса уже была подана заявка на участие в розыгрыше",
        "lotteryPlayerExists" => "Указанный Вами Никнейм уже участвует в розыгрыше, попробуйте ввести другое имя",
        "lotteryYouAreTheWinner" => "Вы недавно побеждали в розыгрыше и заняли первое место. Поэтому Вы сможете принять участие в розыгрыше не ранее чем через $days дней."
    );
    return "" if ($errors{$error} eq "");
    return qq{<div class='alert alert-dismissable alert-danger' id='error'>$errors{$error}</div>}
}

sub logDebug ()
{
    my $m = shift();
    my ($error) = @_;
    print $error;
}

###############################################################################
# SkyWars Top 10

sub skywarsShowTop10 ()
{
    my $m = shift();
    my $dbh = $m->{dbh};
    my ($player, $score, $games_played, $games_won, $kills, $deaths);
    my $sth = $dbh->prepare("SELECT `player_name`, `score`, `games_played`, `games_won`, `kills`, `deaths` FROM `skywars_player` ORDER BY `score` DESC LIMIT 0, 10;");
    $sth->execute();
    $sth->bind_columns(\$player, \$score, \$games_played, \$games_won, \$kills, \$deaths);
    my $html = "<table class='table table-striped table-hover '><thead><tr><th>Игрок</th><th>Сыграно<br/>игр</th><th>К-во<br/>побед</th><th>К-во<br/>убийств</th><th>К-во<br/>смертей</th><th>Набранно<br/>очков</th></tr><tbody>";
    while ($sth->fetch()) {
        $html .= "<tr><td class='text-left'>$player</td><td class='text-left'>$games_played</td><td class='text-left'>$games_won</td><td class='text-left'>$kills</td><td class='text-left'>$deaths</td><td class='text-left'>$score</td></tr>";
    }
    $html .= "</tbody></table>";
    return $html;

}

###############################################################################
# Работа с темами

sub templateLoad ()
{
    my $m = shift ();
    my $cfg = $m->{cfg};
    my $env = $m->{env};
    my $template ||= $cfg->{templateDefault};
    open (my $fh, "<", "$env->{documentRoot}/$cfg->{templatePath}/$template") or die "Не могу открыть шаблон $cfg->{templatePath}/$template : $!";
    $m->{template} = do { local $/; <$fh> };
    close $fh or die "Не могу закрыть шаблон $cfg->{templatePath}/$template: $!";
    return 1;
}

#-----------------------------------------------------------------------------
# Регистрируем переменные для шаблонов

sub templateParse ()
{
    my $m = shift ();
    my $cfg = $m->{cfg};
    my $templateParse = $m->{templateParse};
    $templateParse->{title}                    = sub {return $cfg->{projectName}};
    $templateParse->{serverIp}                 = sub {return $cfg->{serverIp}};
    $templateParse->{serverPort}               = sub {return $cfg->{serverPort}};
    $templateParse->{serverVK}                 = sub {return $cfg->{serverVK}};
    $templateParse->{adminVK}                  = sub {return $cfg->{adminVK}};
    $templateParse->{adminSkype}               = sub {return $cfg->{adminSkype}};
    $templateParse->{adminEmail}               = sub {return $cfg->{adminEmail}};
    $templateParse->{yandexCounter}            = sub {return $cfg->{yandexCounter}};
    $templateParse->{templatePath}             = sub {return $cfg->{templatePath}};
    $templateParse->{donateList}               = sub {return $m->donateList()};
    $templateParse->{donateFormPermgroup}      = sub {return $m->donateForm("permgroup")}; 
    $templateParse->{donateFormPerm}           = sub {return $m->donateForm("perm")};
    $templateParse->{donateFormMoney}          = sub {return $m->donateForm("money")};
    $templateParse->{donateFormItem}           = sub {return $m->donateForm("item")};
    $templateParse->{donateFormRg}             = sub {return $m->donateForm("rgown")};
    $templateParse->{lotteryErrors}            = sub {return $m->lotteryErrors()};
    $templateParse->{lotteryMaxPlayers}        = sub {return $cfg->{lotteryMaxPlayers}};
    $templateParse->{lotteryShowPlayers}       = sub {return $m->showPlayers()};
    $templateParse->{lotteryShowWinners}       = sub {return $m->showWinners()};
    $templateParse->{lotteryShowWinnersToday}  = sub {return $m->showWinnersToday()};
    $templateParse->{lotteryNeedPlayers}       = sub {return $cfg->{lotteryMaxPlayers} - $m->countPlayers ();};
    $templateParse->{playersMax}               = sub {return $m->{playersMax}};
    $templateParse->{playersOnline}            = sub {return $m->{playersOnline}};
    $templateParse->{playersRecord}            = sub {return $m->{playersRecord}};
    $templateParse->{skywarsShowTop10}         = sub {return $m->skywarsShowTop10()};
    $templateParse->{unitpayPublicKey}         = sub {return $cfg->{unitpayPublicKey}};
    $templateParse->{projectDays}              = sub {return $m->projectDays()};

    while ($m->{template} =~ m/\{\{([\w\-\_]+)\}\}/gm) {
        $templateParse->{$1} = sub {return "Err $1"} if (not exists $templateParse->{$1});
    }

    $m->{template} =~ s/\{\{([\w\-\_]+)\}\}/$templateParse->{$1}()/gme;
}

###############################################################################
# Работа с донатом

sub donateForm ()
{
    my $m = shift();
    my ($donateType) = @_;
    my $cfg = $m -> {cfg};
    my $form = $cfg->{donateForm};
    return "<h2>Настройте внешний вид формы оплаты в файле ConfigDonateCMS</h2>" if ("$form" eq "");
    my $formHeader = $cfg->{donateType};
    $formHeader ||= "Покупка доната";
    my $donateList = $m->donateList($donateType);
    return "" if ($donateList eq "");
    $form =~ s/\{\{formHeader\}\}/$formHeader->{$donateType}/gme;
    $form =~ s/\{\{donateList\}\}/$donateList/gme;
    return $form;
}

sub donateList ()
{
    my $m = shift();
    my ($donateType) = @_;
    if ("$donateType" ne "") {
        if (($donateType eq "rgown") or ($donateType eq "rgmem")) {
            $donateType = qq{WHERE ((`type` = "rgown") OR (`type` = "rgmem"))} ;
        }
        else {
            $donateType = qq{WHERE (`type` = "$donateType")} ;
        }
    }
    my $cfg = $m->{cfg};
    my $dbh = $m->{dbh};
    my %donateOptGroup;
    my ($id, $name, $type, $item, $amount, $extra, $server, $price, $html);
    my $sth = $dbh->prepare ("SELECT `id`, `name`, `type`, `item`, `amount`, `extra`, `server`, `price` FROM `shop_cart_items` $donateType ORDER BY (`price`);") or die $!;
    $sth -> execute ();
    $sth -> bind_columns (\$id, \$name, \$type, \$item, \$amount, \$extra, \$server, \$price);
    while ($sth -> fetch ()) {
        my $donateTime = $m->donateTime($item);
        my $option = qq {
            <option value="$id">$name - $price руб. [$donateTime]</option>
        };
        $html .= $option;
        if ($cfg->{enableDonateOptGroup}) {
            $type = "rgown" if ($type eq "rgmem");
            $donateOptGroup{$type} .= $option;
        }
    }
    if ($cfg->{enableDonateOptGroup}) {
        my $donateOptGroupLabel = $cfg->{donateType};
        $html = '';


        if ($cfg->{enableCases}) {
            my $htmlCases = "";
            foreach my $key (keys %{$cfg}) {
                if ($key =~ /donatecase(\d+)/) {
                    $htmlCases .= qq{<option value="$key">$1 Ключей к кейсу - $cfg->{$key} руб.</option>};
                }
            }
            $html .= qq{
                    <optgroup label="Покупка кейсов">
                        $htmlCases
                    </optgroup>
            };

        }

        $html .= qq{<optgroup label="$donateOptGroupLabel->{permgroup}">$donateOptGroup{permgroup}</optgroup>} if ($donateOptGroup{permgroup} ne "");
        $html .= qq{<optgroup label="$donateOptGroupLabel->{perm}">$donateOptGroup{perm}</optgroup>} if ($donateOptGroup{perm} ne "");
        $html .= qq{<optgroup label="$donateOptGroupLabel->{money}">$donateOptGroup{money}</optgroup>} if ($donateOptGroup{money} ne "");
        $html .= qq{<optgroup label="$donateOptGroupLabel->{item}">$donateOptGroup{item}</optgroup>} if ($donateOptGroup{item} ne "");
        $html .= qq{<optgroup label="$donateOptGroupLabel->{rgown}">$donateOptGroup{permgroup}</optgroup>} if ($donateOptGroup{rgown} ne "");
        if ($cfg->{unbanPrice}) {
            $html .= qq{
                    <optgroup label="Разбанить игрока">
                        <option value="unban">Купить разбан игроку за $cfg->{unbanPrice} рублей</option>
                    </optgroup>
            };
        }
        if ($cfg->{enableDonateRecover}) {
            $html .= qq{
                    <optgroup label="Восстановить донат">
                        <option value="donaterecover">Восстановить привилегии - $cfg->{enableDonateRecover}% от стоимости покупок</option>
                    </optgroup>
            };
        }

    }
    return $html;
}

sub donateTime ()
{
    my $m = shift();
    my ($donateItem) = @_;
    my $donateTime = "навсегда";
    if ($donateItem =~ /\?lifetime=(\d+)/) {
        my $days = $1 / 24 / 60 / 60;
        $donateTime = "$days дней"
    }
    return $donateTime;
}

sub donateDescription ()
{
    my $m = shift();
    my ($donateId, $donatePlayer) = @_;
    my ($donateName, $donateItem, $donatePrice, $donateTime);
    my $dbh = $m->{dbh};
    my $cfg = $m->{cfg};
    my $sth = $dbh -> prepare ("SELECT `name`, `item`, `price` FROM `shop_cart_items` WHERE `id` = ? ");
    $sth -> execute ($donateId);
    $sth -> bind_columns (\$donateName, \$donateItem, \$donatePrice);
    $sth -> fetch ();
    $sth -> finish ();
    $donateTime = $m->donateTime($donateItem);
    $donatePrice = $m->donateSum ($donateId, $donatePlayer) if ($cfg->{surcharge} == 1);
    return qq{Покупка $donateName - $donatePrice руб. [$donateTime] для игрока $donatePlayer};
}

sub donateCheck ()
{
    my $m = shift();
    my ($donateId, $donateSum, $donatePlayer) = @_;
    
    return 1 if ($donateId eq "donate");  

    if ($donateSum == $m->donateSum($donateId, $donatePlayer)) {
        return 1;
    }
    else {
        return 0;
    }
}

sub donateSum ()
{
    my $m = shift();
    my ($donateId, $donatePlayer) = @_;
    my $cfg = $m->{cfg};
    my $sum = $m->dbGet("SELECT `price` FROM `shop_cart_items` WHERE `id` = ?", $donateId);
    if (($cfg->{surcharge} == 1) and ("$donatePlayer" ne "")) {
        my $discont = $m->dbGet("SELECT SUM(`price`) FROM `shop_cart_transactions` WHERE (`type` = 'permgroup') and (`player` = ?) AND (`item` NOT LIKE '%lifetime=%')", $donatePlayer);
        $sum = $sum - $discont if ($discont < $sum);
    }
    return $sum;
}

sub donateRecoverSum ()
{
    my $m = shift();
    my ($donatePlayer) = @_;
    my $cfg = $m->{cfg};
    my $sum = $m->dbGet("SELECT SUM(`price`) FROM `shop_cart_transactions` WHERE ((`type` = 'permgroup') or (`type` = 'donaterecover')) and (`player` = ?)", $donatePlayer);
    return int(($sum*$cfg->{enableDonateRecover})/100);
}

sub donateRecover ()
{
    my $m = shift();
    my ($donatePlayer) = @_;
    my $cfg = $m->{cfg};
    $m->dbDo(qq{
        INSERT INTO  `shop_cart`  (`player`, `type`, `item`, `amount`, `extra`, `server`)
          SELECT `player`, `type`, `item`, `amount`, `extra`, `server` FROM `shop_cart_transactions`
            WHERE (`type` = 'permgroup') and (`player` = ?)}, $donatePlayer);
    my $donateName = "Восстановление привилегий";
    my $donateType = "donaterecover";
    my $donateItem = "donaterecover";
    my $donateAmount = 1;
    my $donateServer = 1;
    my $donateExtra;
    my $donatePrice = $m->donateRecoverSum ($donatePlayer);
    $m->dbDo("INSERT INTO `shop_cart_transactions` (`date`, `name`, `player`, `type`, `item`, `amount`, `extra`, `server`, `price`) VALUES (NOW(),?,?,?,?,?,?,?,?)",
        $donateName, $donatePlayer, $donateType, $donateItem, $donateAmount, $donateExtra, $donateServer, $donatePrice);
   
}

sub donateCase ()
{
    my $m = shift();
    my ($donatePlayer, $donateId) = @_;
    my $cfg = $m->{cfg};
    if ($donateId =~ /donatecase(\d+)/) {
        my $count = $1;
        my $i = 0;
        while ($i < $count) {
            $m->dbDo("INSERT INTO `player_keys` (`player`, `key`) VALUES (?, 'don')", $donatePlayer);
            $i = $i + 1;
        }
    }
}

sub donateUnban ()
{
    my $m = shift();
    my ($donatePlayer) = @_;
    my $cfg = $m->{cfg};
    $m->dbDo("DELETE FROM `bans` WHERE `denounced` = LOWER(?)", $donatePlayer);
}

sub donateCheckBan ()
{
    my $m = shift();
    my ($donatePlayer) = @_;
    my $cfg = $m->{cfg};
    return $m->dbGet("SELECT COUNT(*) FROM `bans` WHERE `denounced` = LOWER(?)", $donatePlayer);
}

sub donatePay ()
{
    my $m = shift();
    my ($donateId, $donatePlayer) = @_;
    my ($donateName, $donateType, $donateItem, $donateAmount, $donateExtra, $donateServer, $donatePrice);
    my $dbh = $m->{dbh};
    my $sth = $dbh->prepare("SELECT `name`, `type`, `item`, `amount`, `extra`, `server`, `price` FROM `shop_cart_items` WHERE `id` = ?") or die $!;
    $sth -> execute ($donateId) or die $!;
    $sth -> bind_columns (\$donateName, \$donateType, \$donateItem, \$donateAmount, \$donateExtra, \$donateServer, \$donatePrice);
    $sth -> fetch ();
    $sth -> finish ();
    if (($donateName ne "") and ($donatePlayer ne "") and ($donatePrice ne "")) {
        $m->dbDo("INSERT INTO `shop_cart` (`player`, `type`, `item`, `amount`, `extra`, `server`) VALUES (?,?,?,?,?,?)",
        $donatePlayer, $donateType, $donateItem, $donateAmount, $donateExtra, $donateServer);
        
        $donatePrice = $m->donateSum($donateId, $donatePlayer);
        
        $m->dbDo("INSERT INTO `shop_cart_transactions` (`date`, `name`, `player`, `type`, `item`, `amount`, `extra`, `server`, `price`) VALUES (NOW(),?,?,?,?,?,?,?,?)",
        $donateName, $donatePlayer, $donateType, $donateItem, $donateAmount, $donateExtra, $donateServer, $donatePrice);
    }
}

###############################################################################
# Функции для платежной системы UnitPay

sub unitpayInitParams ()
{
    my $m = shift();
    my $cgi = $m->{cgi};
    my $params = $m->{unitpayParams};
    my @nameParams = $cgi->param();
    foreach my $name (@nameParams) {
        $params->{$1} = $cgi->param($name) if ($name =~ /^params\[(.*)\]/);
    }
}

sub unitpayMd5Sign ()
{
    my $m = shift();
    my $cfg = $m->{cfg};
    my $cgi = $m->{cgi};
    my $secretKey = $cfg->{unitpaySecretKey};
    my $unitpayParams = $m->{unitpayParams};
    delete $unitpayParams->{sign};
    my $s = '';
    foreach my $key (sort keys %{$unitpayParams}) {
        $s .= $unitpayParams->{$key};
    }
    $s .= $secretKey;
    use Digest::MD5 qw(md5_hex);
    my $digest = md5_hex($s);
    return $digest;
}

sub unitpayResponseSuccess ()
{
    my $m = shift();
    my ($message) = @_;
    $message ||= "Запрос успешно обработан";
    print "content-type: application/json\n\n";
    print qq!{"result": {"message":"$message"}}!;
    exit 0;
}

sub unitpayResponseError ()
{
    my $m = shift();
    my ($message) = @_;
    $message ||= "Ошибка при обработке запроса";
    print "content-type: application/json\n\n";
    print qq!{"error": {"code": -32000, "message": "$message"}}!;
    exit 0;
}

sub unitpayCheck ()
{
    my $m = shift();
    my $cfg = $m->{cfg};
    my $unitpayParams = $m->{unitpayParams};
    my ($donateId, $donatePlayer) = split /\|/, $unitpayParams->{account};
    my $donatePrice = $unitpayParams->{orderSum};

    #восстановление доната
    if ($donateId eq "donaterecover") {
        if ($donatePrice == $m->donateRecoverSum($donatePlayer)) {
            $m->unitpayResponseSuccess("Успех");
        }
        else {
            $m->unitpayResponseError("Неверная сумма");
        }
    }

    #кейсы
    if ($donateId =~ /donatecase(\d+)/) {
        if ($donatePrice == $cfg->{$donateId}) {
            $m->unitpayResponseSuccess("Успех");
        }
        else {
            $m->unitpayResponseError("Неверная сумма");
        }
    }

    if ($donateId eq "unban") {
        if ($donatePrice == $cfg->{unbanPrice}) {
            if ($m->donateCheckBan($donatePlayer)) {
                $m->unitpayResponseSuccess("Успех");
            }
            else {
                $m->unitpayResponseError("Игрок $donatePlayer не забанен");
            }
        }
        else {
            $m->unitpayResponseError("Неверная сумма");
        }
    }

    # прием пожертвований для сервера
    if ($donateId eq "donate") {
        $m->unitpayResponseSuccess("Успех");
    }

    if ($m->donateCheck($donateId, $donatePrice, $donatePlayer)) {
        $m->unitpayResponseSuccess("Успех");
    }
    else {
        $m->unitpayResponseError("Неверная сумма");
    }
}

sub unitpayPay ()
{
    my $m = shift();
    my $cfg = $m->{cfg};
    my $unitpayParams = $m->{unitpayParams};
    my ($donateId, $donatePlayer) = split /\|/, $unitpayParams->{account};
    my $donatePrice = $unitpayParams->{orderSum};

    # восстановление доната
    if ($donateId eq "donaterecover") {
        if ($donatePrice == $m->donateRecoverSum($donatePlayer)) {
            $m->donateRecover($donatePlayer);
            $m->unitpayResponseSuccess("Успех");
        }
        else {
            $m->unitpayResponseError("Неверная сумма");
        }
    }

    # кейсы
    if ($donateId=~/donatecase(\d+)/) {
        if ($donatePrice == $cfg->{$donateId}) {
            $m->donateCase($donatePlayer, $donateId);
            $m->unitpayResponseSuccess("Успех");
        }
        else {
            $m->unitpayResponseError("Неверная сумма");
        }
    }

    if ($donateId eq "unban") {
        if ($donatePrice == $cfg->{unbanPrice}) {
            if ($m->donateCheckBan($donatePlayer)) {
                $m->donateUnban($donatePlayer);
                $m->unitpayResponseSuccess("Успех");
            }
            else {
                $m->unitpayResponseError("Игрок $donatePlayer не забанен");
            }
        }
        else {
            $m->unitpayResponseError("Неверная сумма");
        }
    }

    # прием пожертвований для сервера
    if ($donateId eq "donate") {
        $m->unitpayResponseSuccess("Успех");
    }

    if ($m->donateCheck($donateId, $donatePrice, $donatePlayer)) {
        $m->donatePay($donateId, $donatePlayer);
        $m->unitpayResponseSuccess("Успех");
    }
    else {
        $m->unitpayResponseError("Неверная сумма");
    }
}

sub unitpayError ()
{
    my $m = shift();
    $m->unitpayResponseSuccess("Успех");
}

###############################################################################
# Админка

sub adminDonateList ()
{
    my $m = shift();
    my $cfg = $m->{cfg};
    my $dbh = $m->{dbh};
    my ($id, $name, $type, $item, $amount, $extra, $server, $price, $html);
    my $sth = $dbh->prepare ("SELECT `id`, `name`, `type`, `item`, `amount`, `extra`, `server`, `price` FROM `shop_cart_items` ORDER BY (`price`);") or die $!;
    $sth -> execute ();
    $sth -> bind_columns (\$id, \$name, \$type, \$item, \$amount, \$extra, \$server, \$price);
    while ($sth -> fetch ()) {
        $html .= qq {
            <div class="row" id="$id">
                <div class="col-md-6">
                    <strong>$name</strong>: <i class="fa fa-rub">$price</i>
                </div>
                <div class="col-md-6 text-right">
                    <ul class="list-inline">
                        <li>
                            <button class="btn btn-primary btn-sm" onclick="tool.delItem('$id')">
                                <i class="fa fa-times" ></i> Удалить
                            </button>
                        </li>
                        <li>
                            <button class="btn btn-primary btn-sm" onclick="tool.formItemEdit('$id','$name','$type','$item','$amount','$extra','$server','$price')">
                                <i class="fa fa-pencil-square-o"></i> Изменить
                            </button>
                        </li>
                </div>
            </div>
        };
    }
    return $html;
}


sub adminDonateInsert ()
{
    my $m = shift();
    my $cfg = $m->{cfg};
    my $cgi = $m->{cgi};
    my $json_string = $cgi->param('items');
    while ($json_string =~ m/"(.*?)":\{"item":"(.*?)","amount":"(.*?)","type":"(.*?)","price":"(.*?)"\}/gm) {
        my $name = $1;
        my $item = $2;
        my $amount = $3;
        my $type = $4;
        my $price = $5;
        my $isExists = $m->dbGet("SELECT `id` FROM `shop_cart_items` WHERE (`name`=?) AND (`price`=?) AND (`item` = ?)", $name, $price, $item);
        if (!$isExists) {
            $m->dbDo("INSERT `shop_cart_items` (`name`, `type`, `item`, `amount`, `price`, `server`) VALUES (?,?,?,?,?,1);", $name, $type, $item, $amount, $price);
        }
    }
    
    #    22.04.2015 на некоторых хостингах стали удалить этот модуль.
    #    use JSON::XS;
    #    my $json_string = $cgi->param('items');
    #    my $json_xs = JSON::XS->new();
    #    $json_xs->utf8(1);
    #    my $href = $json_xs->decode($json_string);
    #    for my $key (keys %{$href}) {
    #        my $name = $key;
    #        my $amount = ${$href}{$key}{amount};
    #        my $item = ${$href}{$key}{item};
    #        my $type = ${$href}{$key}{type};
    #        my $price = ${$href}{$key}{price};
    #
    #        my $isExists = $m->dbGet("SELECT `id` FROM `shop_cart_items` WHERE (`name`=?) AND (`price`=?) AND (`item` = ?)", $name, $price, $item);
    #
    #        if (!$isExists) {
    #            $m->dbDo("INSERT `shop_cart_items` (`name`, `type`, `item`, `amount`, `price`, `server`) VALUES (?,?,?,?,?,1);", $name, $type, $item, $amount, $price);
    #        }
    #        else {
    #        }
    #    }
}

sub adminDonateDelete ()
{
    my $m = shift();
    my $cfg = $m->{cfg};
    my $cgi = $m->{cgi};
    my $id = $cgi->param("id");
    $m->dbDo("DELETE FROM `shop_cart_items` WHERE `id` = ?", $id);
}

sub adminDonateUpdate ()
{
    my $m = shift();
    my $cfg = $m->{cfg};
    my $cgi = $m->{cgi};
    my $id = $cgi->param("id");
    my $name = $cgi->param("name");
    my $type = $cgi->param("type");
    my $amount = $cgi->param("amount");
    my $price = $cgi->param("price");
    my $item = $cgi->param("item");
    $m->dbDo("UPDATE `shop_cart_items` SET `name`=?,`type`=?,`item`=?,`amount`=?,`price`=? WHERE `id` = ?", $name, $type, $item, $amount, $price, $id);
}


###############################################################################
# Низкоуровневые функции для работы с БД

#------------------------------------------------------------------------------
# Подключение к БД

sub dbConnect 
{
    my $m = shift();
    my $cfg = $m->{cfg};
    my $dbh = undef;
    eval { require DBI } or $m->error("DBI module not available.");
    $DBI::VERSION >= 1.30 or $m->error("DBI is too old, need at least 1.30.");
    eval { require DBD::mysql } or $m->error("DBD::mysql module not available.");
    $DBD::mysql::VERSION >= 2.9003 
        or $m->error("DBD::mysql is too old, need at least 2.9003, preferably 4.0 or newer.");
    my $dbName = $cfg->{dbName};
    $dbh = DBI->connect(
        "dbi:mysql:database=$dbName;host=$cfg->{dbServer};$cfg->{dbParam}", 
        $cfg->{dbUser}, $cfg->{dbPassword}) or die "Не возможно подключиться к базе данных$!";
    $dbh -> do("set character set utf8");
    $dbh -> do("set names utf8");
    $dbh -> {'LongTruncOk'} = 1;
    $dbh -> {'LongReadLen'} = 1000000;
    $m->{mysql} = 1;
    $m->{dbh} = $dbh;
}

sub dbInsertId
{
    my $m = shift();
    my $table = shift();
    return $m->{dbh}{mysql_insertid} if $m->{mysql};
}

sub dbDo
{
    my $m = shift();
    my $query = shift();
    my @values = @_;
    my $cfg = $m->{cfg};
    my $sth = $m->{dbh}->prepare($query) or $m->dbError();
    my $result = $sth->execute(@values);
    defined($result) or $m->dbError();
    return $result;
}

sub dbGet () 
{
    my $m = shift ();
    my $sql = shift ();
    my @values = @_;
    my $val = '';
    my $sth = $m->{dbh}->prepare($sql) or $m->dbError();
    $sth -> execute (@values) or $m->dbError();
    $sth -> bind_columns (\$val);
    $sth -> fetch ();
    $sth -> finish ();
    return $val;
}

sub dbError ()
{
    my $m = shift ();
    #
    # Написать код для записи запроса в лог в случае ошибки и установленного флага
    #
}


sub logError ()
{

}

sub md5 ()
{
    my $m = shift ();
    my $data = shift ();
    my $rounds = shift () || 1;
    my $base64url = shift () || 0;

    require Digest::MD5;
    utf8::encode($data) if utf8::is_utf8($data);
    if ($rounds > 1) { $data = Digest::MD5::md5($data) for 1 .. $rounds - 1 }
    if ($base64url) {
        $data = Digest::MD5::md5_base64($data);
        $data =~ tr!+/!-_!;
    }
    else {
        $data = Digest::MD5::md5_hex($data);
    }
    return $data;
}

sub hashPassword ()
{
    my $m = shift ();
    my $password = shift ();
    my $salt = shift ();
    return $m->md5($password . $salt, 100000, 1);
}

# Все хорошо ;-)
1;
