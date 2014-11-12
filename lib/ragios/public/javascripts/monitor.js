$(function() {

    var getMonitorId = _.memoize(function () {
        return $("#monitor-id").html().trim();
    });

    var $loadingBtn;

    var AppController = {
        init: function () {
            this.message = $("#message");
        },

        success: function () {
            AppController.message.attr('class', 'text-success');
            AppController.message.show( function() {
                $( this ).text( "Success!" );
            });
            AppController.message.fadeOut(5000);
        },

        error: function ( xhr ) {
            AppController.message.attr('class', 'text-danger');
            AppController.message.show( function() {
                var response = $.parseJSON(xhr.responseText);
                $( this ).text( response.error );
            });
            AppController.message.fadeOut(5000);
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
                AppController.error]
            );
        }
    }


    var monitorController = {

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
            monitorController.editor.set(cleanData);
        },

        update: function () {
            var attributesToUpdate = _.omit(this.editor.get(), ['_id','_rev','created_at_', 'status_', 'type', 'current_state_']);
            var attributesJson = JSON.stringify( attributesToUpdate );
            ragios.update( getMonitorId(), attributesJson, AppController.success, AppController.error );
        },

        find: function () {
            ragios.find( getMonitorId(), this.render, AppController.error );
        },

        restart: function () {
            if( ragiosHelper.confirm("Are you sure you want to restart this monitor?") ) {
                ragios.restart( getMonitorId(), AppController.success, AppController.error );
            }
        },

        stop: function () {
            if( ragiosHelper.confirm("Are you sure you want to stop this monitor?") ) {
                ragios.stop( getMonitorId(), AppController.success, AppController.error );
            }
        },

        test: function () {
            if( ragiosHelper.confirm("Are you sure you want to test this monitor?") ) {
                ragios.test( getMonitorId(), AppController.success, AppController.error);
            }
        },

        delete: function () {
            if( ragiosHelper.confirm("Are you sure you want to delete this monitor?") ) {
                var deleteSuccess = function () {
                    ragiosHelper.back_to_index();
                };
                ragios.delete( getMonitorId(), deleteSuccess, AppController.error );
            }
        }
    };

    var notificationsController = {

        init: function () {
            this.startDate = $("#notification-start-date");
            this.endDate = $("#notification-end-date");
            this.initDatePicker();
            this.initTable();
        },

        initDatePicker:  function () {
            AppController.initDatePicker(
                this.startDate,
                this.endDate,
                moment().startOf('week'),
                moment()
            );
        },

        initTable: function () {
            var createTable = function( data ) {
                notificationsController.table =
                $('#notifications-datatable').dataTable({
                    "order": [ 0, 'desc' ],
                    "data": notificationsController.cleanData(data),
                    "columns": [
                        { "data": "time", "width": "25%" },
                        { "data": "id", "width": "25%" },
                        { "data": "notifier", "width": "25%" },
                        { "data": "event", "width": "25%" }
                    ]
                });
            };

            AppController.refreshTable(
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
            AppController.reloadTable( notificationsController.table, notificationsController.cleanData(data) );
        },

        refreshTable: function () {
            AppController.refreshTable(
                this.startDate.data("DateTimePicker").getDate(),
                this.endDate.data("DateTimePicker").getDate(),
                ragios.getNotifications,
                this.reloadTable
            );
        }
    }


    var resultsController = {

        init: function () {
            this.startDate = $("#test-results-start-date");
            this.endDate = $("#test-results-end-date");
            this.initDatePicker();
            this.initTable();
        },

        initDatePicker:  function () {
            AppController.initDatePicker(
                this.startDate,
                this.endDate,
                moment().startOf('day'),
                moment()
            );
        },

        initTable: function () {
            var createTable = function( data ) {
                resultsController.table =
                $('#test-results-datatable').dataTable({
                    "order": [ 0, 'desc' ],
                    "data": resultsController.cleanData(data),
                    "columns": [
                        { "data": "time", "width": "25%" },
                        { "data": "id", "width": "25%" },
                        { "data": "state", "width": "25%" },
                        { "data": "test_result", "width": "25%" }
                    ]
                });
            };

            AppController.refreshTable(
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
                    state: ragiosHelper.formatState(data.state),
                    test_result: ragiosHelper.formatResults(data.test_result)
                };
            });
        },

        reloadTable: function (data) {
            AppController.reloadTable( resultsController.table, resultsController.cleanData(data) );
        },

        refreshTable: function () {
            AppController.refreshTable(
                this.startDate.data("DateTimePicker").getDate(),
                this.endDate.data("DateTimePicker").getDate(),
                ragios.getResults,
                this.reloadTable
            );
        }
    }



    var failuresController = {

        init: function () {
            this.startDate = $("#failures-start-date");
            this.endDate = $("#failures-end-date");
            this.initDatePicker();
            this.initTable();
        },

        initDatePicker:  function () {
            AppController.initDatePicker(
                this.startDate,
                this.endDate,
                moment().startOf('week'),
                moment()
            );
        },

        initTable: function () {
            var createTable = function( data ) {
                failuresController.table =
                $('#failures-datatable').dataTable({
                    "order": [ 0, 'desc' ],
                    "data": failuresController.cleanData(data),
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
                AppController.error
            );
        },

        cleanData: function (data) {
            return _.map(data, function(data) {
                return {
                    time: ragiosHelper.formatDate(data.time_of_test),
                    id: data._id,
                    state: ragiosHelper.formatState(data.state),
                    test_result: ragiosHelper.formatResults(data.test_result)
                };
            });
        },

        reloadTable: function (data) {
            AppController.reloadTable( failuresController.table, failuresController.cleanData(data) );
        },

        refreshTable: function () {
            ragios.getResultsByState(
                getMonitorId(),
                "failed",
                this.startDate.data("DateTimePicker").getDate().format(),
                this.endDate.data("DateTimePicker").getDate().format(),
                this.reloadTable,
                AppController.error
            );
        }
    }


    var errorsController = {

        init: function () {
            this.startDate = $("#errors-start-date");
            this.endDate = $("#errors-end-date");
            this.initDatePicker();
            this.initTable();
        },

        initDatePicker:  function () {
            AppController.initDatePicker(
                this.startDate,
                this.endDate,
                moment().startOf('week'),
                moment()
            );
        },

        initTable: function () {
            var createTable = function( data ) {
                errorsController.table =
                $('#errors-datatable').dataTable({
                    "order": [ 0, 'desc' ],
                    "data": errorsController.cleanData(data),
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
                AppController.error
            );
        },

        cleanData: function (data) {
            return _.map(data, function(data) {
                return {
                    time: ragiosHelper.formatDate(data.time_of_test),
                    id: data._id,
                    state: ragiosHelper.formatState(data.state),
                    test_result: ragiosHelper.formatResults(data.test_result)
                };
            });
        },

        reloadTable: function (data) {
            AppController.reloadTable( errorsController.table, errorsController.cleanData(data) );
        },

        refreshTable: function () {
            ragios.getResultsByState(
                getMonitorId(),
                "error",
                this.startDate.data("DateTimePicker").getDate().format(),
                this.endDate.data("DateTimePicker").getDate().format(),
                this.reloadTable,
                AppController.error
            );
        }
    }

    $(document).on({
        ajaxStart: function() {
            if( $loadingBtn ) { $loadingBtn.button('loading'); }
        },
        ajaxStop: function() {
            if( $loadingBtn ) { $loadingBtn.button('reset'); }
        }
    });

    $( ".btn" ).on("click", function (){
        $loadingBtn  = $(this);
    });

    $( "#update-monitor-button" ).on("click", function() {
        monitorController.update();
    });

    $( ".refresh-monitor-button" ).on("click", function() {
        monitorController.find();
    });

    $( "#restart-button" ).on("click", function() {
        monitorController.restart();
    });

    $( "#stop-button" ).on("click", function() {
        monitorController.stop();
    });

    $( "#test-button" ).on("click", function() {
        monitorController.test();
    });

    $( "#delete-button" ).on("click", function() {
        monitorController.delete();
    });

    $( "#refresh-notifications-button" ).on("click", function() {
        notificationsController.refreshTable();
    });

    $( "#refresh-test-results-button" ).on("click", function() {
        resultsController.refreshTable();
    });

    $( "#refresh-failures-button" ).on("click", function() {
        failuresController.refreshTable();
    });

    $( "#refresh-errors-button" ).on("click", function() {
        errorsController.refreshTable();
    });

    AppController.init();
    monitorController.init();
    notificationsController.init();
    resultsController.init();
    failuresController.init();
    errorsController.init();
});
