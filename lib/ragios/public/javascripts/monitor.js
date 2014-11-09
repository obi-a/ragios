$(function() {

    var getMonitorId = _.memoize(function () {
        return $("#monitor-id").html().trim();
    });

    var $loadingBtn;

    var util = {
        init: function () {
            this.message = $("#message");
        },

        success: function () {
            util.message.attr('class', 'text-success');
            util.message.show( function() {
                $( this ).text( "Success!" );
            });
            util.message.fadeOut(5000);
        },

        error: function ( xhr ) {
            util.message.attr('class', 'text-danger');
            util.message.show( function() {
                var response = $.parseJSON(xhr.responseText);
                $( this ).text( response.error );
            });
            util.message.fadeOut(5000);
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

        reloadTable: function (table, data) {
            table.fnClearTable();
            if(data.length > 0 ) { table.fnAddData(data); }
        },

        refreshTable: function (startDate, endDate, request, renderTable) {
            request.apply(
                ragios,
                [getMonitorId(),
                startDate.format(),
                endDate.format(),
                renderTable,
                util.error]
            );
        },

        formatResults: function (result) {
            return _.reduce(_.pairs(result), function( memo, pair ) {
                return memo.toString() + "\n" + pair;
            });
        },

        formatDate: function (date) {
            return moment(date).format('llll')
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
            ragios.update( getMonitorId(), attributesJson, util.success, util.error );
        },

        find: function () {
            ragios.find( getMonitorId(), this.render, util.error );
        },

        restart: function () {
            if( ragiosHelper.confirm("Are you sure you want to restart this monitor?") ) {
                ragios.restart( getMonitorId(), util.success, util.error );
            }
        },

        stop: function () {
            if( ragiosHelper.confirm("Are you sure you want to stop this monitor?") ) {
                ragios.stop( getMonitorId(), util.success, util.error );
            }
        },

        test: function () {
            if( ragiosHelper.confirm("Are you sure you want to test this monitor?") ) {
                ragios.test( getMonitorId(), util.success, util.error);
            }
        },

        delete: function () {
            if( ragiosHelper.confirm("Are you sure you want to delete this monitor?") ) {
                var deleteSuccess = function () {
                    ragiosHelper.back_to_index();
                };
                ragios.delete( getMonitorId(), deleteSuccess, util.error );
            }
        }
    };

    var notifications = {

        init: function () {
            this.startDate = $("#notification-start-date");
            this.endDate = $("#notification-end-date");
            this.initDatePicker();
            this.initTable();
        },

        initDatePicker:  function () {
            util.initDatePicker(
                notifications.startDate,
                notifications.endDate,
                moment().startOf('week'),
                moment()
            );
        },

        initTable: function () {
            var createTable = function( data ) {
                notifications.table =
                $('#notifications-datatable').dataTable({
                    "order": [ 0, 'desc' ],
                    "data": notifications.cleanData(data),
                    "columns": [
                        { "data": "time", "width": "25%" },
                        { "data": "id", "width": "25%" },
                        { "data": "notifier", "width": "25%" },
                        { "data": "event", "width": "25%" }
                    ]
                });
            };

            util.refreshTable(
                moment().startOf('week'),
                moment(),
                ragios.getNotifications,
                createTable
            );
        },

        cleanData: function (data) {
            return _.map(data, function(data) {
                return {
                    time: ragiosHelper.formatDate(data.created_at),
                    id: data._id,
                    notifier: data.notifier,
                    event: data.event
                };
            });
        },

        reloadTable: function (data) {
            util.reloadTable( notifications.table, notifications.cleanData(data) );
        },

        refreshTable: function () {
            util.refreshTable(
                notifications.startDate.data("DateTimePicker").getDate(),
                notifications.endDate.data("DateTimePicker").getDate(),
                ragios.getNotifications,
                this.reloadTable
            );
        }
    }


    var results = {

        init: function () {
            this.startDate = $("#test-results-start-date");
            this.endDate = $("#test-results-end-date");
            this.initDatePicker();
            this.initTable();
        },

        initDatePicker:  function () {
            util.initDatePicker(
                results.startDate,
                results.endDate,
                moment().startOf('day'),
                moment()
            );
        },

        initTable: function () {
            var createTable = function( data ) {
                results.table =
                $('#test-results-datatable').dataTable({
                    "order": [ 0, 'desc' ],
                    "data": results.cleanData(data),
                    "columns": [
                        { "data": "time", "width": "25%" },
                        { "data": "id", "width": "25%" },
                        { "data": "state", "width": "25%" },
                        { "data": "test_result", "width": "25%" }
                    ]
                });
            };

            util.refreshTable(
                moment().startOf('day'),
                moment(),
                ragios.getResults,
                createTable
            );
        },

        cleanData: function (data) {
            return _.map(data, function(data) {
                return {
                    time: ragiosHelper.formatDate(data.time_of_test),
                    id: data._id,
                    state: data.state,
                    test_result: ragiosHelper.formatResults(data.test_result)
                };
            });
        },

        reloadTable: function (data) {
            util.reloadTable( results.table, results.cleanData(data) );
        },

        refreshTable: function () {
            util.refreshTable(
                results.startDate.data("DateTimePicker").getDate(),
                results.endDate.data("DateTimePicker").getDate(),
                ragios.getResults,
                this.reloadTable
            );
        }
    }



    var failures = {

        init: function () {
            this.startDate = $("#failures-start-date");
            this.endDate = $("#failures-end-date");
            this.initDatePicker();
            this.initTable();
        },

        initDatePicker:  function () {
            util.initDatePicker(
                failures.startDate,
                failures.endDate,
                moment().startOf('week'),
                moment()
            );
        },

        initTable: function () {
            var createTable = function( data ) {
                failures.table =
                $('#failures-datatable').dataTable({
                    "order": [ 0, 'desc' ],
                    "data": failures.cleanData(data),
                    "columns": [
                        { "data": "time", "width": "25%" },
                        { "data": "id", "width": "25%" },
                        { "data": "state", "width": "25%" },
                        { "data": "test_result", "width": "25%" }
                    ]
                });
            };

            ragios.getResultsByState(
                getMonitorId(),
                "failed",
                moment().startOf('week').format(),
                moment().format(),
                createTable,
                util.error
            );
        },

        cleanData: function (data) {
            return _.map(data, function(data) {
                return {
                    time: ragiosHelper.formatDate(data.time_of_test),
                    id: data._id,
                    state: data.state,
                    test_result: ragiosHelper.formatResults(data.test_result)
                };
            });
        },

        reloadTable: function (data) {
            util.reloadTable( failures.table, failures.cleanData(data) );
        },

        refreshTable: function () {
            ragios.getResultsByState(
                getMonitorId(),
                "failed",
                failures.startDate.data("DateTimePicker").getDate().format(),
                failures.endDate.data("DateTimePicker").getDate().format(),
                failures.reloadTable,
                util.error
            );
        }
    }


    var errors = {

        init: function () {
            this.startDate = $("#errors-start-date");
            this.endDate = $("#errors-end-date");
            this.initDatePicker();
            this.initTable();
        },

        initDatePicker:  function () {
            util.initDatePicker(
                errors.startDate,
                errors.endDate,
                moment().startOf('week'),
                moment()
            );
        },

        initTable: function () {
            var createTable = function( data ) {
                errors.table =
                $('#errors-datatable').dataTable({
                    "order": [ 0, 'desc' ],
                    "data": errors.cleanData(data),
                    "columns": [
                        { "data": "time", "width": "25%" },
                        { "data": "id", "width": "25%" },
                        { "data": "state", "width": "25%" },
                        { "data": "test_result", "width": "25%" }
                    ]
                });
            };

            ragios.getResultsByState(
                getMonitorId(),
                "error",
                moment().startOf('week').format(),
                moment().format(),
                createTable,
                util.error
            );
        },

        cleanData: function (data) {
            return _.map(data, function(data) {
                return {
                    time: ragiosHelper.formatDate(data.time_of_test),
                    id: data._id,
                    state: data.state,
                    test_result: ragiosHelper.formatResults(data.test_result)
                };
            });
        },

        reloadTable: function (data) {
            util.reloadTable( errors.table, errors.cleanData(data) );
        },

        refreshTable: function () {
            ragios.getResultsByState(
                getMonitorId(),
                "error",
                errors.startDate.data("DateTimePicker").getDate().format(),
                errors.endDate.data("DateTimePicker").getDate().format(),
                errors.reloadTable,
                util.error
            );
        }
    }

    $(document).on({
        ajaxStart: function() {
            if( $loadingBtn !== undefined ) { $loadingBtn.button('loading'); }
        },
        ajaxStop: function() {
            if( $loadingBtn !== undefined ) { $loadingBtn.button('reset'); }
        }
    });

    $( ".btn" ).on("click", function (){
        $loadingBtn  = $(this);
    });

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
        notifications.refreshTable();
    });

    $( "#refresh-test-results-button" ).on("click", function() {
        results.refreshTable();
    });

    $( "#refresh-failures-button" ).on("click", function() {
        failures.refreshTable();
    });

    $( "#refresh-errors-button" ).on("click", function() {
        errors.refreshTable();
    });

    util.init();
    monitor.init();
    notifications.init();
    results.init();
    failures.init();
    errors.init();
});
