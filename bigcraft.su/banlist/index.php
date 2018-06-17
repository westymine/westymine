<?
	require('config.php');
	
	if ( isset($_POST['nickname']{3}) ) {
		$search = "WHERE `name` = '".mysql_real_escape_string($_POST['nickname'])."'";
	}
	
	/* Страницы */
	$pages_max = mysql_num_rows(mysql_query("SELECT `id` FROM {$cfg['table_Banlist']}"));
	$page_last = floor($pages_max/$cfg['page_output']);
	
	if ( is_numeric($_GET['page']) && $_GET['page'] > 0 && $_GET['page'] <= $page_last ) $page_id = $_GET['page']; else $page_id = 0;
	
	$page_max = $page_id * $cfg['page_output'];
	/* Страницы */
	
	$query_banlist = mysql_query("SELECT * FROM {$cfg['table_Banlist']} {$search} ORDER BY `id` ASC LIMIT {$page_max}, {$cfg['page_output']}");
	
	$query__banlist = mysql_query("SELECT COUNT(*) FROM {$cfg['table_Banlist']}");
	$row  = mysql_fetch_row($query__banlist);
	$totalbans = $row[0]; 
		
	while($row = mysql_fetch_array($query_banlist))
		$output .= '
			<tr>
				<td><img src="http://cravatar.eu/helmavatar/'.$row['player'].'/25.png" alt="'.$row['player'].'"/> '.$row['player'].'</td>
				<td>'.($row['type'] ? $row['type'] : $cfg['text_reason_not']).'</td>
				<td>'.($row['expire'] ? date($cfg['date_format'], $row['expire']) : '<font color="red">'.$cfg['text_ban_forever'].'</font>').'</td>
				<td>'.($row['reason'] ? $row['reason'] : $cfg['text_reason_not']).'</td>
				<td><img src="http://cravatar.eu/helmavatar/'.$row['owner'].'/25.png" alt="'.$row['owner'].'"/> '.$row['owner'].'</td>
			</tr>
		';	
	
	if ( !$output ) $error = '<div align="center"><h3>Список нарушитилей пуст.</h3></div>';
	
	/* Страницы */
	
	if ( $page_last > 0 ) {
		for($i = 0; $i <= $cfg['page_btn']; ++$i) 
		{
			$page_id_i = $i + ($page_id - $cfg['page_btn']/2);
			if ( $page_id_i >= 0 && $page_id_i <= $page_last ) 
				$pages_btn .= '<a href="?page='.$page_id_i.'" class="button" style="'.($page_id == $page_id_i ? 'background: #fff;' : false).'">'.$page_id_i.'</a> ';
		}
			
		$page = '
			<div class="bl-pages">
				<a href="?page='.($page_id - 1).'" class="button"><</a>
				<a href="?page=0" class="button"><<</a>
				
				'.$pages_btn.'
				
				<a href="?page='.$page_last.'" class="button">>></a>
				<a href="?page='.($page_id + 1).'" class="button">></a>
			</div>
		';
	}
	/* Страницы */
?>
<title>Нарушители | UniversalWorld</title>
<meta charset="UTF-8">
    <nav class="navbar navbar-inverse navbar-fixed-top">
      <div class="container">
        <div class="navbar-header">
          <button type="button" class="navbar-toggle collapsed" data-toggle="collapse" data-target="#navbar" aria-expanded="false" aria-controls="navbar">
            <span class="sr-only">Скрыть навигацию</span>
            <span class="icon-bar"></span>
            <span class="icon-bar"></span>
            <span class="icon-bar"></span>
          </button>
          <a class="navbar-brand" href="/" style="color: #FFD700">BigCraft</a>
        </div>
        <div id="navbar" class="navbar-collapse collapse">
            <ul class="nav navbar-nav">
                <li><a href="/"><i class="fa fa-home"></i> Главная</a></li>
				<li><a href="http://universalw.su/?go=surcharge"><i class="fa fa-user-plus"></i> Доплата</a></li>
				<li><a href="http://universalw.su/?go=news"><i class="fa fa-users"></i> Новости</a></li>
				<li><a href="http://universalw.su/banlist/index.php"><i class="fa fa-users"></i> Нарушитили</a></li>
            </ul>
        </div>
      </div>
    </nav>
	<br>
	<br>
	<br>
<link rel="stylesheet" type="text/css" href="banlist.css">
		<div class="container">
		<br>
					<? if ( $cfg['search_on'] ) { ?>
						<form method="POST" class="input-group">
							<input type="text" name="nickname" class="form-control" placeholder="Ник игрока" required/>
							<span class="input-group-btn">
							<input type="submit" class="btn btn-primary" value="Найти"/>
							</span>
						</form>
						
					<? } ?>
	
					<table class = "table table-striped table-bordered table-hover" border="1px">
					<thead>
						<tr>
							<td width="300">Нарушитель</td>
							<td width="240">Тип наказания</td>
							<td width="240">Будет прощён</td>
							<td width="240">Причина</td>
							<td width="300">Наказал</td>
						</tr>
					</thead>
						<tbody>
						<?=$output?>
						</tbody>
					</table>
					
					<?=$error.'<br/>'.$page?>
				<div align="center">
				Общее количество наказаний: <?=$totalbans?><br>
				Developer by <a href="http://vk.com/sashok724" target="_blank"><img src="http://cravatar.eu/helmavatar/sashok724/20.png"> ZerO724</a>
				<div>
		</div>