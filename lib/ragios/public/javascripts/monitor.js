$(function() {

    var getMonitorId = function () {
        return $("#monitor-id").html().trim();
    };
    var monitorEditorContainer = document.getElementById("monitor-editor");

    var monitorEditorOptions = {
        mode: 'tree',
        modes: ['tree', 'form', 'view', 'code', 'text'],
        error: function (err) {
            console.log(err.toString());
        }
    };

    var currentStateEditorContainer = document.getElementById("current-state-editor");

    var currentStateEditorOptions = {
        mode: 'view',
        error: function (err) {
            console.log(err.toString());
        }
    };

    var monitorEditor = new JSONEditor(monitorEditorContainer, monitorEditorOptions);

    var currentStateEditor = new JSONEditor(currentStateEditorContainer, currentStateEditorOptions);

    var renderMonitor = function (data) {
        var current_state = data.current_state_
        cleanData = _.omit(data, ['_id','_rev', 'type', 'current_state_']);
        monitorEditor.set(cleanData);
        currentStateEditor.set(current_state);
    }

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

    ragios.find( getMonitorId(), renderMonitor, error );

    $( "#update-monitor-button" ).click(function() {
        var attributesToUpdate = _.omit(monitorEditor.get(), ['_id','_rev','created_at_', 'status_', 'type', 'current_state_']);
        var attributesJson = JSON.stringify( attributesToUpdate );
        ragios.update( getMonitorId(), attributesJson, success, error );
    });

    $( ".refresh-monitor-button" ).click(function() {
        ragios.find( getMonitorId(), renderMonitor, error );
    });

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
