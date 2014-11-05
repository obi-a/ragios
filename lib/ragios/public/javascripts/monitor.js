$(function() {

    var getMonitorId = _.memoize(function () {
        return $("#monitor-id").html().trim();
    });

    //var $notificationStartDate = $("#notification-start-date");

    //var $notificationEndDate = $("#notification-end-date");

    var notificationsTable;

    var notifications = {
        init: function () {
            this.startDate = $("#notification-start-date");
            this.endDate = $("#notification-end-date");
        }
    }

    var initDatePicker = function (startDatePicker, endDatePicker, startDate, endDate) {
        startDatePicker.datetimepicker({
            defaultDate: startDate
        });
        endDatePicker.datetimepicker({
            defaultDate: endDate
        });
        startDatePicker.on("dp.change", function (e) {
           endDatePicker.data("DateTimePicker").setMinDate(e.date);
        });
        endDatePicker.on("dp.change", function (e) {
           startDatePicker.data("DateTimePicker").setMaxDate(e.date);
        });
    };
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

    var notificationsData = function(data) {
        return _.map(data, function(data) {
                    return {
                        time: data.created_at,
                        id: data._id,
                        notifier: data.notifier,
                        event: data.event
                    };
        });
    };

    var initNotificationsTable = function( data ) {
        notificationsTable =
        $('#notifications-datatable').dataTable({
            "order": [ 0, 'desc' ],
            "data": notificationsData(data),
            "columns": [
                { "data": "time" },
                { "data": "id" },
                { "data": "notifier" },
                { "data": "event" }
            ]
        });
    };

    var monitor = {

        init: function () {
            this.createEditor();
            this.find();
        },

        createEditor: function () {
            var editorOptions = {
                mode: 'tree',
                modes: ['tree', 'form', 'view', 'code', 'text'],
                error: function (err) {
                    console.log(err.toString());
                }
            };

            this.editor = new JSONEditor(
                document.getElementById("monitor-editor"),
                editorOptions
            );
        },

        render: function (data) {
            var cleanData = _.omit(data, ['_id','_rev', 'type']);
            monitor.editor.set(cleanData);
        },

        update: function () {
            var attributesToUpdate = _.omit(this.editor.get(), ['_id','_rev','created_at_', 'status_', 'type', 'current_state_']);
            var attributesJson = JSON.stringify( attributesToUpdate );
            ragios.update( getMonitorId(), attributesJson, success, error );
        },

        find: function () {
            ragios.find( getMonitorId(), this.render, error );
        },

        restart: function () {
            if( ragiosHelper.confirm("Are you sure you want to restart this monitor?") ) {
                ragios.restart( getMonitorId(), success, error );
            }
        },

        stop: function () {
            if( ragiosHelper.confirm("Are you sure you want to stop this monitor?") ) {
                ragios.stop( getMonitorId(), success, error );
            }
        },

        test: function () {
            if( ragiosHelper.confirm("Are you sure you want to test this monitor?") ) {
                ragios.test( getMonitorId(), success, error);
            }
        },

        delete: function () {
            if( ragiosHelper.confirm("Are you sure you want to delete this monitor?") ) {
                var deleteSuccess = function () {
                    ragiosHelper.back_to_index();
                };
                ragios.delete( getMonitorId(), deleteSuccess, error );
            }
        }
    };

    var reloadTable = function(table, data) {
        table.fnClearTable();
        if(data.length > 0 ) { table.fnAddData(data); }
    };

    var reloadNotificationsTable = function (data) {
        reloadTable( notificationsTable, notificationsData(data) );
    };

    var refreshTable = function(startDate, endDate, request, renderTable) {
        request.apply(
            ragios,
            [getMonitorId(),
            startDate.format(),
            endDate.format(),
            renderTable,
            error]
        );
    };

    $( "#update-monitor-button" ).on("click", function() {
        monitor.update();
    });

    $( ".refresh-monitor-button" ).on("click", function() {
        monitor.find();
    });

    $( "#restart-button" ).on("click", function() {
        monitor.restart();
    });

    $( "#stop-button" ).on("click", function() {
        monitor.stop();
    });

    $( "#test-button" ).on("click", function() {
        monitor.test();
    });

    $( "#delete-button" ).on("click", function() {
        monitor.delete();
    });

    $( "#refresh-notifications-button" ).on("click", function() {
        refreshTable(
            notifications.startDate.data("DateTimePicker").getDate(),
            notifications.endDate.data("DateTimePicker").getDate(),
            ragios.getNotifications,
            reloadNotificationsTable
        );
    });

    notifications.init();

    refreshTable(
        moment().startOf('week'),
        moment(),
        ragios.getNotifications,
        initNotificationsTable
    );

    initDatePicker(
        notifications.startDate,
        notifications.endDate,
        moment().startOf('week'),
        moment()
    );
    monitor.init();
});
