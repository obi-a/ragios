$(function() {
    ragiosHelper.init_add_field();

    $('#update-button').click( function () {
        ragios.add( JSON.stringify( getMonitor() ), success, error )
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
