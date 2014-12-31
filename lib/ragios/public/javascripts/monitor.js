$(function() {

    var getMonitorId = _.memoize(function () {
        return $("#monitor-id").html().trim();
    });

    var $loadingBtn;

    var Util = {
        init: function () {
            this.message = $("#message");
            _.templateSettings = {
                interpolate: /\{\{(.+?)\}\}/g
            };
            this.messageTemplate = _.template( $('#message-template').html() );
        },
        success: function (data) {
            Util.message.append(
                Util.messageTemplate({message: "Success", alert: "success", response: JSON.stringify(data)})
            );
        },
        error: function ( xhr ) {
            var response = $.parseJSON(xhr.responseText);
            Util.message.append(
               Util.messageTemplate({message: "Error", alert: "danger", response: JSON.stringify(response)})
            );
        }
    }

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
            ragios.update( getMonitorId(), attributesJson, Util.success, Util.error );
        },
        find: function () {
            ragios.find( getMonitorId(), this.render, Util.error );
        },
        start: function () {
            if( ragiosHelper.confirm("Are you sure you want to start this monitor?") ) {
                ragios.start( getMonitorId(), Util.success, Util.error );
            }
        },
        stop: function () {
            if( ragiosHelper.confirm("Are you sure you want to stop this monitor?") ) {
                ragios.stop( getMonitorId(), Util.success, Util.error );
            }
        },
        test: function () {
            if( ragiosHelper.confirm("Are you sure you want to test this monitor?") ) {
                ragios.test( getMonitorId(), Util.success, Util.error);
            }
        },
        delete: function () {
            if( ragiosHelper.confirm("Are you sure you want to delete this monitor?") ) {
                var deleteSuccess = function () {
                    ragiosHelper.back_to_index();
                };
                ragios.delete( getMonitorId(), deleteSuccess, Util.error );
            }
        }
    };

    var EventTable = {
        create: function(startDateSelector, endDateSelector, tableSelector) {
            return Object.create(this).init(startDateSelector, endDateSelector, tableSelector)
        },
        init: function(startDateSelector, endDateSelector, tableSelector) {
            this.startDatePicker = $(startDateSelector);
            this.endDatePicker = $(endDateSelector);
            this.tableSelector = $(tableSelector);
            this.initDatePicker( this.startDatePicker, this.endDatePicker, moment().startOf('day'), moment().endOf('day') );
            return this;
        },
        initDatePicker: function (startDatePicker, endDatePicker, startDate, endDate) {
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
        },
        buildTable: function () {
            this.reset(
                moment().startOf('day'),
                moment(),
                this.createTable
            );
        },
        refreshTable: function () {
            this.reset(
                this.startDatePicker.data("DateTimePicker").getDate(),
                this.endDatePicker.data("DateTimePicker").getDate(),
                this.reloadTable
            );
        }
    }

    var eventsByState = {
        columns: function () {
            return [
                { "data": "time", "width": "25%" },
                { "data": "id", "width": "25%" },
                { "data": "state", "width": "25%" },
                { "data": "event", "width": "25%" }
            ]
        },
        cleanData: function (data) {
            return _.map(data, function(data) {
                return {
                    time: ragiosHelper.formatDate(data.time),
                    id: ragiosHelper.formatEventId(data._id),
                    state: ragiosHelper.formatState(data.state),
                    event: ragiosHelper.formatResults(data.event)
                };
            });
        }
    }

    var failures =  EventTable.create(
        "#failures-start-date",
        "#failures-end-date",
        "#failures-datatable"
    );

    _.extend(failures, eventsByState, {
        createTable: function( data ) {
            failures.table =
            failures.tableSelector.dataTable({
                "order": [ 0, 'desc' ],
                "data": failures.cleanData(data),
                "columns": failures.columns()
            });
        },
        reloadTable: function (data) {
            failures.table.fnClearTable();
            if(data.length > 0 ) { failures.table.fnAddData( failures.cleanData(data) ); }
        },
        reset: function (startDate, endDate, renderTable) {
            ragios.getResultsByState(
                getMonitorId(),
                "failed",
                startDate.format(),
                endDate.format(),
                renderTable,
                Util.error
            );
        }
    });

    var errors = EventTable.create(
        "#errors-start-date",
        "#errors-end-date",
        "#errors-datatable"
    );

    _.extend(errors, eventsByState, {
        createTable: function( data ) {
            errors.table =
            errors.tableSelector.dataTable({
                "order": [ 0, 'desc' ],
                "data": errors.cleanData(data),
                "columns": errors.columns()
            });
        },
        reloadTable: function (data) {
            errors.table.fnClearTable();
            if(data.length > 0 ) { errors.table.fnAddData( errors.cleanData(data) ); }
        },
        reset: function (startDate, endDate, renderTable) {
            ragios.getResultsByState(
                getMonitorId(),
                "error",
                startDate.format(),
                endDate.format(),
                renderTable,
                Util.error
            );
        }
    });

    var notifications = EventTable.create(
        "#notification-start-date",
        "#notification-end-date",
        "#notifications-datatable"
    );

    _.extend(notifications, {
        createTable: function( data ) {
            notifications.table =
            notifications.tableSelector.dataTable({
                "order": [ 0, 'desc' ],
                "data": notifications.cleanData(data),
                "columns": notifications.columns()
            });
        },
        columns: function() {
            return [
                { "data": "time", "width": "25%" },
                { "data": "id", "width": "25%" },
                { "data": "notifier", "width": "25%" },
                { "data": "event", "width": "25%" }
            ]
        },
        cleanData: function (data) {
            return _.map(data, function(data) {
                return {
                    time: ragiosHelper.formatDate(data.time),
                    id: ragiosHelper.formatEventId(data._id),
                    notifier: data.notifier,
                    event: ragiosHelper.formatResults(data.event)
                };
            });
        },
        reloadTable: function (data) {
            notifications.table.fnClearTable();
            if(data.length > 0 ) { notifications.table.fnAddData( notifications.cleanData(data) ); }
        },
        reset: function (startDate, endDate, renderTable) {
            ragios.getNotifications(
                getMonitorId(),
                startDate.format(),
                endDate.format(),
                renderTable,
                Util.error
            );
        }

    });

    var allEvents = EventTable.create(
        "#all-events-start-date",
        "#all-events-end-date",
        '#all-events-datatable'
    );
    _.extend(allEvents, {
        reset: function(startDate, endDate, renderTable) {
            ragios.getEvents(
                getMonitorId(),
                startDate.format(),
                endDate.format(),
                renderTable,
                Util.error
            );
        },
        createTable: function(data) {
            allEvents.table =
            allEvents.tableSelector.dataTable({
                "order": [ 0, 'desc' ],
                "data": allEvents.cleanData(data),
                "columns": allEvents.columns()
            });
        },
        reloadTable: function (data) {
            allEvents.table.fnClearTable();
            if(data.length > 0 ) { allEvents.table.fnAddData( allEvents.cleanData(data) ); }
        },
        columns: function () {
            return [
                { "data": "time", "width": "20%" },
                { "data": "id", "width": "20%" },
                { "data": "state", "width": "20%" },
                { "data": "event_type", "width": "20%" },
                { "data": "event", "width": "20%" }
            ]
        },
        cleanData: function (data) {
            return _.map(data, function(data) {
                return {
                    time: ragiosHelper.formatDate(data.time),
                    id: ragiosHelper.formatEventId(data._id),
                    state: ragiosHelper.formatState(data.state),
                    event_type: data.event_type,
                    event: ragiosHelper.formatResults(data.event)
                };
            });
        }
    });

    $(document).on({
        ajaxStart: function() {
            if( $loadingBtn ) { $loadingBtn.button('loading'); }
        },
        ajaxStop: function() {
            if( $loadingBtn ) { $loadingBtn.button('reset'); }
        }
    });
    $( ".btn" ).on("click", function (){ $loadingBtn  = $(this); });
    $( "#start-button" ).on("click", function() { monitor.start(); });
    $( "#stop-button" ).on("click", function() { monitor.stop(); });
    $( "#test-button" ).on("click", function() { monitor.test(); });
    $( "#delete-button" ).on("click", function() { monitor.delete(); });
    $( "#update-monitor-button" ).on("click", function() { monitor.update(); });
    $( "#refresh-monitor-button" ).on("click", function() { monitor.find(); });
    $( "#refresh-all-events-button" ).on("click", function() { allEvents.refreshTable(); });
    $( "#refresh-notifications-button" ).on("click", function() {  notifications.refreshTable(); });
    $( "#refresh-failures-button" ).on("click", function() { failures.refreshTable(); });
    $( "#refresh-errors-button" ).on("click", function() { errors.refreshTable(); });

    $('body').on('hidden.bs.modal', '.modal', function () {
        $(this).removeData('bs.modal');
    });

    Util.init();
    monitor.init();
    allEvents.buildTable();
    notifications.buildTable();
    failures.buildTable();
    //2 seconds delay prevents couchDB update conflict when creating the events_by_state view for the first time
    //because both failures.buildTable and errors.buildTable will attempt to create the view if it doesnt exist
    setTimeout(function(){
        errors.buildTable();
    }, 2000);
});
