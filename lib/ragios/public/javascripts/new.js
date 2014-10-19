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


    ragiosHelper.init_add_field();

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


    $('#source-tab').click( function () {
        $("#json").html(getMonitorJson());
    });

    var getUnnamedFields = function () {
        var fields = ragiosHelper.getValues(".new-monitor-field", function() {
            return $(this).val();
        });
        var values = ragiosHelper.getValues(".new-monitor-value", function() {
            return $(this).val();
        });
        return _.object(fields, values);
    }

    var getKnownFields = function () {
        var knownFields = {
            monitor: $("#monitor").val(),
            every: $("#every").val(),
            via: $("#via").val(),
            plugin: $("#plugin").val()
        };

        return knownFields;
    };

    var getMonitor = function () {
        return _.extend(getKnownFields(), getUnnamedFields());
    };

    var getMonitorJson = function () {
        return JSON.stringify(getMonitor(), undefined, 2);
    };
});
