$(function() {

    var getMonitorId = _.memoize(function () {
        return $("#monitor-id").html().trim();
    });

    var createCurrentStateEditor = function () {
        var currentStateEditorContainer = document.getElementById("current-state-editor");

        var currentStateEditorOptions = {
            mode: 'view',
            error: function (err) {
                console.log(err.toString());
            }
        };

        return new JSONEditor(currentStateEditorContainer, currentStateEditorOptions);
    };

    var createMonitorEditor = function () {
        var monitorEditorContainer = document.getElementById("monitor-editor");

        var monitorEditorOptions = {
            mode: 'tree',
            modes: ['tree', 'form', 'view', 'code', 'text'],
            error: function (err) {
                console.log(err.toString());
            }
        };

        return new JSONEditor(monitorEditorContainer, monitorEditorOptions);
    };

    var monitorEditor = createMonitorEditor();
    var currentStateEditor = createCurrentStateEditor();

    var renderMonitor = function (data) {
        var current_state = data.current_state_
        var cleanData = _.omit(data, ['_id','_rev', 'type', 'current_state_']);
        monitorEditor.set(cleanData);
        currentStateEditor.set(current_state);
    }

    var $message = $("#message");

    var success = function () {
        $message.attr('class', 'text-success');
        $message.show( function() {
            $( this ).text( "Success!" );
        });
        $message.fadeOut(5000);
    };

    var error =  function ( xhr ) {
        $message.attr('class', 'text-danger');
        $message.show( function() {
            var response = $.parseJSON(xhr.responseText);
            $( this ).text( response.error );
        });
        $message.fadeOut(5000);
    };

    var renderNotifications = function( data ) {
        var notifications = _.map(data, function(data) {
            return {
                time: data.created_at,
                id: data._id,
                notifier: data.notifier,
                event: data.event
            };
        });

        $('#notifications-datatable').dataTable({
            "order": [ 0, 'desc' ],
            "data": notifications,
            "columns": [
                { "data": "time" },
                { "data": "id" },
                { "data": "notifier" },
                { "data": "event" }
            ]
        });
    };

    var updateMonitor = function () {
        var attributesToUpdate = _.omit(monitorEditor.get(), ['_id','_rev','created_at_', 'status_', 'type', 'current_state_']);
        var attributesJson = JSON.stringify( attributesToUpdate );
        ragios.update( getMonitorId(), attributesJson, success, error );
    };

    var findMonitor = function () {
        ragios.find( getMonitorId(), renderMonitor, error );
    };

    var restartMonitor =  function () {
        if( ragiosHelper.confirm("Are you sure you want to restart this monitor?") ) {
            ragios.restart( getMonitorId(), success, error );
        }
    };

    var stopMonitor =  function () {
        if( ragiosHelper.confirm("Are you sure you want to stop this monitor?") ) {
            ragios.stop( getMonitorId(), success, error );
        }
    };

    var testMonitor = function () {
        if( ragiosHelper.confirm("Are you sure you want to test this monitor?") ) {
            ragios.test( getMonitorId(), success, error);
        }
    };

    var deleteMonitor = function () {
        if( ragiosHelper.confirm("Are you sure you want to delete this monitor?") ) {
            var deleteSuccess = function () {
                ragiosHelper.back_to_index();
            };
            ragios.delete( getMonitorId(), deleteSuccess, error );
        }
    };

    $( "#update-monitor-button" ).on("click", function() {
        updateMonitor();
    });

    $( ".refresh-monitor-button" ).on("click", function() {
        findMonitor();
    });

    $( "#restart-button" ).on("click", function() {
        restartMonitor();
    });

    $( "#stop-button" ).on("click", function() {
        stopMonitor();
    });

    $( "#test-button" ).on("click", function() {
         testMonitor();
    });

    $( "#delete-button" ).on("click", function() {
        deleteMonitor();
    });

    ragios.getNotifications( getMonitorId(), renderNotifications, error );

    findMonitor();
});
