$(function() {
    $('#add-field-button').click(function () {
        $('#new-monitor-table').append('<tr><td><textarea class="new-monitor-field" rows="1" style="width: 100%;"></textarea></td><td ><textarea class="new-monitor-value" rows="1" style="width: 100%;"></textarea></td><td><span class="delete-field glyphicon glyphicon-remove" data-toggle="tooltip" data-placement="top" title="Delete field"></span></td></tr>');
        $('.delete-field').click(function () {
            $(this).closest('tr')
                   .remove();

        });
    });

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

    var getValues = function (selector) {
        var fields =
        $(selector)
            .map(function() {
                return $(this).val();
        }).get();

        return fields;
    }

    var getUnnamedFields = function () {
        var fields = getValues(".new-monitor-field");
        var values = getValues(".new-monitor-value");
        return _.object(fields, values)
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
       return $.extend({}, getKnownFields(), getUnnamedFields());
    };

    var getMonitorJson = function () {
       return JSON.stringify(getMonitor(), undefined, 2);
    };
});
