$(function() {

    var getMonitorId = function () {
        return $("#monitor-id").html().trim();
    };
    var container = document.getElementById("monitor-editor");
    var editor = new JSONEditor(container);

    ragios.find( getMonitorId(), renderMonitor, error );

    var renderMonitor = function (data) {
        console.log(JSON.parse(data));
        editor.set(JSON.parse(data));
    }

    //clean up/DRY up later
    var success = function () {
        $( "#message").attr('class', 'text-success');
        $( "#message" ).show( function() {
            $( this ).text( "Success!" );
        });
        $("#message").fadeOut(5000);
    };

    var error =  function ( xhr ) {
        $( "#message").attr('class', 'text-danger');
        $( "#message" ).show( function() {
            var response = $.parseJSON(xhr.responseText);
            $( this ).text( response.error );
        });
        $("#message").fadeOut(5000);
    };



    ragiosHelper.init_add_field();
    ragiosHelper.init_delete_field();

    var getAddedFields = function () {
        var fields = ragiosHelper.getValues(".monitor-field", function() {
            return $(this).val();
        });
        var values = ragiosHelper.getValues(".monitor-value", function() {
            return $(this).val();
        });
        return _.object(fields, values);
    }

    var getExistingFields = function () {
        var fields = ragiosHelper.getValues(".monitor-field", function() {
            return $(this).text().trim();
        });
        var values = ragiosHelper.getValues(".monitor-value", function() {
            return $(this).val();
        });
        return _.object(fields, values);
    }

    $( "#update-monitor-button" ).click(function() {
        var attributesToUpdate = _.omit(getMonitorFromTable(), ['_id','_rev','created_at_', 'status_', 'type', '']);
        console.log(attributesToUpdate);
        var attributesJson = JSON.stringify( attributesToUpdate );
        console.log(attributesJson);
        ragios.update( getMonitorId(), attributesJson, success, error );
    });

    var getMonitorFromTable = function () {
        return _.extend(getExistingFields(), getAddedFields());
    }

    $( "#restart-button" ).click(function() {
        if( ragiosHelper.confirm("Are you sure you want to restart this monitor?") ) {
            ragios.restart( getMonitorId(), success, error );
        }
    });

    $( "#stop-button" ).click( function() {
        if( ragiosHelper.confirm("Are you sure you want to stop this monitor?") ) {
            ragios.stop( getMonitorId(), success, error );
        }
    });

    $( "#test-button" ).click( function() {
        if( ragiosHelper.confirm("Are you sure you want to test this monitor?") ) {
            ragios.test( getMonitorId(), success, error);
        }
    });

    $( "#delete-button" ).click( function() {
        if( ragiosHelper.confirm("Are you sure you want to delete this monitor?") ) {
            var deleteSuccess = function () {
                ragiosHelper.back_to_index();
            };
            ragios.delete( getMonitorId(), deleteSuccess, error );
        }
    });
});
