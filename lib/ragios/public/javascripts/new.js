$(function() {
    var element = document.getElementById('monitor-editor');
    var $loadingBtn;

    var message = $("#message");
    _.templateSettings = {
        interpolate: /\{\{(.+?)\}\}/g
    };
    var messageTemplate = _.template( $('#message-template').html() );

    JSONEditor.defaults.options.iconlib = "bootstrap3";

    // Set an option during instantiation
    var editor = new JSONEditor(element, {
        disable_collapse: true,
        theme: 'bootstrap3',
        schema: {
            title: "Monitor",
            type: "object",
            properties: {
                monitor: { "type": "string" },
                every: {"type": "string"},
                via: {"type": "array"},
                plugin: {"type": "string"}
            }
        }
    });

    var success =  function () {
        ragiosHelper.back_to_index();
    }

    var error =  function ( xhr ) {
        var response = $.parseJSON(xhr.responseText);
        message.append(
            messageTemplate({message: "Error", alert: "danger", response: JSON.stringify(response)})
        );
    };

    $(document).on({
        ajaxStart: function() {
            if($loadingBtn) { $loadingBtn.button('loading'); }
        },
        ajaxStop: function() {
            if($loadingBtn) { $loadingBtn.button('reset'); }
        }
    });

    $( ".btn" ).on("click", function (){
        $loadingBtn  = $(this);
    });

    $('#update-button').on("click", function () {
        var monitor = editor.getValue();
        ragios.add( JSON.stringify( monitor ), success, error )
    });

});
