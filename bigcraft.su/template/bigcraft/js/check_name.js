$(document).ready(function(){
	
	var timeoutId, user_sum=0, privelege_sum=0;
	
	$('#inputName').keyup(function(){
			if ($('#inputName').val()!='') {
				check_name($('#inputName').val());
			}
	});
	
	$('#hide').hide();
	$('#sum').text('');
	$('#inputName').val('');
	
	$('#inputStatus').change(function(){
		check_privelege($(this).val());
	});
	
	function check_name(name) {
		$.post(
			'/ajax/surchargeSumByNick.pl',
			{
				name: name
			},
			function(data){
				if (data!='') {
					user_sum = data;
					$.post(
						'/ajax/surchargePriv.pl',
						{
							user_sum: user_sum
						},
						function(data){
                            $('#hide').fadeIn();
							$('select[name="donateItem"]').html('<option selected disabled value="">Выбeрите привилегию для доплаты</option>'+data);
						}
					);
					$('#pay').removeClass('btn-danger').addClass('btn-success').html('<i class="fa fa-shopping-cart"></i> Доплатить <span id="sumss"></span><span id="sum"></span> <i id="rubrub" class=""></i>');
				} else {
					$('#hide').fadeOut();
					$('#pay').removeClass('btn-success').addClass('btn-danger').html('У Вас нет привилегии');
					user_sum = 0;
				}
			}
		);
	}
	
	function check_privelege(privelege) {
		$.post(
			'/ajax/surchargeSumByPriv.pl',
			{
				privelege: privelege
			},
			function(data){
				if (data!='') {
					privelege_sum = data;
					if (privelege_sum-user_sum>0) {
						$('#sum').text(privelege_sum-user_sum);
                        $("#sumss").html(privelege_sum-user_sum);
                        document.getElementById("rubrub").className = 'fa fa-rub';
					} else {
						$("#alert_error").removeClass('hidden');
						$('#sum').text('');
                        $("#sumss").html("");
					}
				}
			}
		);
	}
	
	$('#pay').click(function(){
		if ($('#sum').text()=='') {
			return false;
		} else {
			//$.post(
			//	'/payment.pl',
		//		{
		//			donatePlayer: $('#inputName').val(),
		//			donateItem: $('select[name="group"]').val(),
		//		},
		//		function(data){
		//			if (data!='РѕС€РёР±РєР°') {
		//				location.href = data;
		//			} else {
		//				$("#alert_error").removeClass('hidden');
		//			}
		//		}
		//	);
		//	return false;
              $(location).attr("href", "/payment.pl?donatePlayer=" + $('#inputName').val() + "&donateItem=" +  $('select[name="group"]').val());
		}
	});
	
});