<?
	$cfg = array(
		
		'db_host' 			=> '', //Хост.
		
		'db_name'			=> '', //Имя.
		
		'db_user' 			=> 'root', //Имя юзера.
		
		'db_pass' 			=> 'ghj2k45BMfBNDkghfJKGSKghocuJUTRfxkHKGKGHfFFJFgfjfjartwcvn', //Пароль.
		
		'db_charset' 		=> 'UTF-8', //Кодировка.
		
		
		'table_Banlist' 	=> 'bigban', //Название таблицы с банами.
		
		'date_format'		=> 'd M, Y g:ia', //Формат даты.
		
		'text_reason_not'	=> 'Не указана', //Текст при отсутствии причины в колонке "Причина". (Не указана, Причины нет, Причина не указана, ...)
		
		'text_ban_forever'	=> 'Никогда', //Текст вечного бана в колонке "Дата разбана". (Перманентно, Никогда, невозможна, ...)
		
		'search_on' 		=> false, //Включить поиск по игрокам.
		
		'page_output' 		=> 10, //Кол-во выводимых записей на страницу.
		
		'page_btn' 			=> 6, //Кол-во кнопок страниц. Указывать четное число и не совсем много.
	);
	
	$mysql_connect = mysql_connect($cfg['db_host'], $cfg['db_user'], $cfg['db_pass']) or die(mysql_error()); 
	mysql_select_db($cfg['db_name'], $mysql_connect) or die(mysql_error()); 
	mysql_query("SET NAMES '".$cfg['db_charset']."'");