//= require jquery-ui/widget
//= require fileupload/jquery.iframe-transport
//= require fileupload/jquery.fileupload
//= require_self
$(function () {

  ///Retirar o div invisivel de template para fora da tag form
  $('.repo-template').insertAfter($('form.new_album_photo'));

  ////Evento do click do botão de excluir o arquivo
  $('#upload-preview').on('click', '.close', function(){
    $(this).parents('.closeable').fadeOut(function(){
      $(this).remove();
    })
  });

  $('#current-photos').on('ajax:success', '.close', function(e, data, status, xhr) {
    $(this).parents('.closeable').fadeOut(function(){
      $(this).remove();
    })
  }).on('ajax:error', '.close', function(e, xhr, status, error) {
    console.log(error);

  }).on('ajax:success', '.edit_album_photo', function(e, data, status, xhr) {
    $(this).find('.save-btn').addClass('hide');
  }).on('ajax:error', '.edit_album_photo', function(e, xhr, status, error) {
    console.log(error);
  });

  $('[name="album_photo[description]"]').keyup(function(e){
    $(this).closest('form').find('.save-btn').removeClass('hide');
  });

  function switch_disable_text(disable){
    var $submit = $('.send-files');
    var $dis_txt = $submit.val();
    $submit.val($submit.data('disable-with')).data('disable-with', $dis_txt).prop('disabled', disable);
  }

  function handleFail(context, errors){
    var $msg = context.find('.status');
    $msg.html(null);
    for(var idx in errors){
       $msg.append('<span class="label label-important">'+errors[idx]+'</span>&nbsp;');
    }
  }

  ////Não envia o submit do form principal, e chama o data.submit de cada arquivo incluido
  $('form.new_album_photo').submit(function(){
    if($('.repo-item').length == 0){
      return false;
    }
    $('.repo-item').each(function(){
      //alert($(this).text());
      $(this).find('.status').html('<img src="'+assetPath('loading-bar.gif')+'"/>').addClass('loading');
      var $data = $(this).data('dataobj');
      //console.log($data);
      $data.formData = {"album_photo[description]" : $(this).find('#album_photo_description').val()};
      $data.submit();
    });
    switch_disable_text(true);
    return false;
  });

  $('form.new_album_photo').fileupload({
    paramName: 'album_photo[image]',
    dataType: 'json',
    url: $('form.new_album_photo').prop('action') + '.json',
    ////Evento de inclusão de arquivo, chamado para cada arquivo selecionado
    add: function (e, data) {
      ////Validação se o arquivo já foi incluído
      var included = false;
      $(".repo-item .file-name").each(function(){
        console.log($(this).text().trim(), data.files[0].name)
        if($(this).text().trim() == data.files[0].name){
          included = true;
        }
      });
      if(included){
        return;
      }

      $('form.new_album_photo .form-actions').removeClass('hide');

      var $repoItem = $('.repo-template').clone(true);

      $repoItem.removeClass('repo-template').addClass('repo-item').show();
      $repoItem.find('#album_photo_image').val(data.files[0].name);
      $repoItem.find('.file-name').text(data.files[0].name);
      /////Geração do thumbnail de preview (Se o browser tiver o FileReader)
      if ((/image/i).test(data.files[0].type)) {
        var img = document.createElement('img');
        img.src = URL.createObjectURL(data.files[0]);
        $(img).addClass('preview');
        $repoItem.find('#album_photo_image').hide().after(img);
      }

      $repoItem.appendTo($('#upload-preview'));
      $repoItem.data('dataobj', data);

      data.context = $repoItem;
    },
    /////Evento de retorno do processamento, executado para cada envio, executando tanto success ou failure
    always: function (e, data) {
        var $msg = data.context.find('.status');
        $msg.removeClass('loading');
        if($('.status.loading').length == 0){
          switch_disable_text(false);
        }
    },
    done: function (e, data) {
       ///No IE, mesmo com erro, ele dispara a função done, vindo do iframe
        if(data.result.errors){
           handleFail(data.context, data.result.errors);
        }else{
          var $repoItem = data.context;

          $repoItem.find('.status').html('<span class="label label-success">'+data.result.message+'</span>');
          $repoItem.removeClass('repo-item');
          $repoItem.find('#album_photo_description').prop('disabled', true);
          //$repoItem.find('img.preview').wrap($('<a href="'+data.result.repository.archive_url+'" target="_blank"></a>'));
        }
     },

     fail: function(e, data) {
         console.log(e);
         console.log(data);
        //console.log(data.jqXHR.responseText);
        try{
          var errors = JSON.parse(data.jqXHR.responseText).errors;
        }catch(e){
          var errors = [data.jqXHR.responseText.split(/\r?\n/)[0]]
        }
        handleFail(data.context, errors)
     }
  });
});
