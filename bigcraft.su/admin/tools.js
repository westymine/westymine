function Tools(){
    this.count = 1;
    this.addItemForm = function(el){
        var co = this.count;
        this.count++;
        $("#hr").before(
            "<hr><div class='border' name='itemDonate'>"+
            "<select name='type' id='type"+co+"' class='form-control' onchange='tool.changeAddItemForm("+co+")'>" +
            "<option value='permgroup'>Привилегия</option>"+
            "<option value='perm'>Команда</option>"+
            "<option value='money'>Деньги</option>"+
            "<option value='item'>Блок/Предмет</option>"+
            "<option value='rgown'>Владелец региона</option>"+
            "<option value='rgmem'>Участник региона</option>"+
            "</select><br/>"+
            "<input type='text' name='name' class='form-control' id='name"+co+"' placeholder='Название привилегии'><br>"+
            "<input type='text' name='item' class='form-control' id='item"+ co +"' placeholder='Название группы в permissions'><br>"+
            "<input type='text' name='amount' class='form-control' id='amount"+ co +"' placeholder='Количество' style='display: none;' value=1><br>"+
            "<input type='text' name='price' class='form-control' id='price"+co+"' placeholder='Стоимость привилегии'><br>"+
            "<div id='lifetimeblock"+co+"'>"+
            "<label id=lifetime"+ co +"><input type='radio' name='lifetime' onclick='tool.showLifeTime(true, "+ co +")'>На время</label><br>"+
            "<label><input type='radio' name='lifetime' onclick='tool.showLifeTime(false, "+ co +")'>Навсегда</label>"+
            "</div>"+
            "</div><br>"
        );
    }

    this.changeAddItemForm = function(id) {
        var currentType = $("#type"+id).val();
        if ((currentType == "permgroup") || (currentType == "perm")) {
            $("#lifetimeblock"+id).show();
        }
        else {
            $("#lifetimeblock"+id).hide();
            var text = $("#item"+ id).val();
            if(text.indexOf('?', 0) != -1){
                var position = text.indexOf('?', 0);
                text = text.substr(0, position);
                $("#item"+ id).val(text);
            }
        }
        if ((currentType == "permgroup") || (currentType == "perm") || (currentType == "rgown") || (currentType == "rgmem")) {
            $("#amount"+id).hide();
            $("#amount"+id).val("1");
        }
        else {
            $("#amount"+id).show();
        }
        if (currentType == "money") {
            $("#item"+id).hide();
            $("#item"+id).val('');
            $("#amount"+id).attr("placeholder", "Количество денег");
            $("#name"+id).attr("placeholder", "Название");
            $("#price"+id).attr("placeholder", "Стоимость");
        }
        else {
            $("#item"+id).show();
            $("#amount"+id).val("1");
        }
        if (currentType == "item") {
            $("#amount"+id).val('');
            $("#amount"+id).attr("placeholder", "Количество блока/предмета");
            $("#name"+id).attr("placeholder", "Название блока/предмета");
            $("#price"+id).attr("placeholder", "Стоимость блока/предмета");
            $("#item"+id).attr("placeholder", "ID блока/предмета");
        }
        if (currentType == "permgroup") {
            $("#amount"+id).val('1');
            $("#amount"+id).attr("placeholder", "Количество");
            $("#name"+id).attr("placeholder", "Название привилегии");
            $("#price"+id).attr("placeholder", "Стоимость привилегии");
            $("#item"+id).attr("placeholder", "Название группы в permissions");
        }
        if (currentType == "perm") {
            $("#amount"+id).val('1');
            $("#amount"+id).attr("placeholder", "Количество");
            $("#name"+id).attr("placeholder", "Название команды");
            $("#price"+id).attr("placeholder", "Стоимость команды");
            $("#item"+id).attr("placeholder", "Название permissions команды");
        }
        if ((currentType == "rgown") || (currentType == "rgmem")) {
            $("#amount"+id).val('1');
            $("#amount"+id).attr("placeholder", "Количество");
            $("#name"+id).attr("placeholder", "Название региона");
            $("#price"+id).attr("placeholder", "Стоимость региона");
            $("#item"+id).attr("placeholder", "Название региона в WorldGuard");
        }
    }
	
    this.formItemEdit = function(id, name, type, item, amount, extra, server, price){  
        var co = this.count;
        this.count++;
        var selected
        $("#" + id).before(
            "<hr><div class='border' name='formItemsEdit"+ id +"'>"+
            "<select name='type' id='type"+co+"' class='form-control' onchange='tool.changeAddItemForm("+co+")'>" +
            "<option value='permgroup'>Привилегия</option>"+
            "<option value='perm'>Команда</option>"+
            "<option value='money'>Деньги</option>"+
            "<option value='item'>Блок/Предмет</option>"+
            "<option value='rgown'>Владелец региона</option>"+
            "<option value='rgmem'>Участник региона</option>"+
            "</select><br/>"+
            "<input type='text' name='name' class='form-control' id='name"+ co +"' placeholder='Название привилегия' value='" + name + "'><br>"+
            "<input type='text' name='item' class='form-control' id='item"+ co +"' placeholder='Название группы в permissions' value='" + item + "'><br>"+
            "<input type='text' name='amount' class='form-control' id='amount"+ co +"' placeholder='Количество' value='"+ amount +"'><br>"+
            "<input type='text' name='price' class='form-control' id='price"+ co +"' placeholder='Стоимость привилегия' value='" + price + "'><br>"+
            "<div id='lifetimeblock"+co+"'>"+
            "<label id=lifetime"+ co +"><input type='radio' name='lifetime' onclick='tool.showLifeTime(true, "+ co +")'>На время</label><br>"+
            "<label><input type='radio' name='lifetime' onclick='tool.showLifeTime(false, "+ co +")'>Навсегда</label>"+
            "</div></div><br>"+
            "<button class='btn btn-sx btn-success' onclick=tool.itemEdit(" + id + ")>Изменить</button><br/>"
        );
        $("#" + id).remove();
        $("#type"+co).val(type);
        tool.changeAddItemForm(co);

    }

	this.delItem = function(name){
		$.get('/admin.pl', {'action': 'delitem', 'id': name}, function(data){
			alert(data);
			$("#"+name).hide('fast').remove();
		});
	}
	
    this.addItems = function(){
        var itemsDonate = $("[name = 'itemDonate']");
        obj = "obj = {";
        $.each(itemsDonate, function(i, itemDonate){
            obj += "\""+$(itemDonate).find("[name = 'name']").val()+"\"";
            obj += ":{\"item\":\""+$(itemDonate).find("[name = 'item']").val()+"\",";
            obj += "\"amount\":\""+$(itemDonate).find("[name = 'amount']").val()+"\",";
            obj += "\"type\":\""+$(itemDonate).find("[name = 'type']").val()+"\",";
            obj += "\"price\":\""+$(itemDonate).find("[name = 'price']").val()+"\"},";
        });
        obj += "}";
        obj = JSON.stringify(eval(obj));
        $.post('/admin.pl', {'action': 'additems', 'items': obj}, function(data){
            alert(data);
        });
    }
 
    this.itemEdit = function(id){
        var $el = $("[name = formItemsEdit"+ id +"]");
        var name = $el.find("[name = 'name']").val();
        var item = $el.find("[name = 'item']").val();
        var amount = $el.find("[name = 'amount']").val();
        var price = $el.find("[name = 'price']").val();
        var type = $el.find("[name = 'type']").val();
        $.get('/admin.pl', {'action': 'itemUpdate', 'id': id, 'name': name, 'type': type, 'item': item, 'amount': amount, 'price': price}, function(data){
            alert(data);
        });
    }
	
	this.showLifeTime = function(show, id){
		var $el = $("#lifetime"+ id);
		if(show && $("#lifetime-count"+ id).length == 0){
			$el.after("<input type='text' class='form-control' id=lifetime-count"+ id +" onchange='tool.lifeTime("+ id +")' placeholder='Введите количество дней'><br>");
		}
		else{
			var $el_text = $("#item"+ id);
			var text = $el_text.val();
			if(text.indexOf('?', 0) != -1){
				var position = text.indexOf('?', 0);
				text = text.substr(0, position);
				$el_text.val(text);
			}
			$("#lifetime-count"+ id).remove();
		}
	}
	
	this.lifeTime = function(id){
		var $el_text = $("#item"+ id);
		var text = $el_text.val();
		if(text.indexOf('?', 0) == -1){
			var $el_days = $("#lifetime-count"+ id);
			var days = $el_days.val();
			var count = days * 24 * 60 * 60;
			$el_text.val(text +"?lifetime="+ count);
		}
		else{
			var position = text.indexOf('?', 0);
			text = text.substr(0, position);
			var $el_days = $("#lifetime-count"+ id);
			var days = $el_days.val();
			var count = days * 24 * 60 * 60;
			$el_text.val(text +"?lifetime="+ count);
		}
	}
 
}

var tool = new Tools();