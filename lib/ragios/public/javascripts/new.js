$(function() {
    var element = document.getElementById('monitor-editor');

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

    $('#update-button').click( function () {
        console.log();
        var monitor = editor.getValue();
        ragios.add( JSON.stringify( monitor ), success, error )
    });

    var success =  function () {
        ragiosHelper.back_to_index();
    }

    var error =  function ( xhr ) {
        $( "#message").attr('class', 'text-danger');
        $( "#message" ).show( function() {
            var response = $.parseJSON(xhr.responseText);
            $( this ).text( response.error );
        });
    };
});