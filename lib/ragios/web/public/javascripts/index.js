$(function() {

    var monitors = new Monitors();

    var cleanData = function(data) {
        return _.map(data, function(data) {
            return {
                _id: ragiosHelper.linkTo(data._id, "/admin/monitors/" + data._id),
                created_at_: ragiosHelper.formatDateSmall(data.created_at_),
                monitor: data.monitor,
                every: data.every,
                via: data.via,
                plugin: data.plugin,
                status_: ragiosHelper.formatStatus(data.status_)
            };
        });
    };

    var createTable = function( _, data ) {
        var monitorsList =
        $('#monitors-list-datatable').dataTable({
            "bStateSave": true,
            "order": [ 0, 'desc' ],
            "data": cleanData(data),
            "columns": [
                { "data": "created_at_", "width": "12%" },
                { "data": "_id", "width": "31%" },
                { "data": "monitor", "width": "35%" },
                { "data": "every", "width": "1%" },
                { "data": "via", "width": "12%" },
                { "data": "plugin", "width": "8%" },
                { "data": "status_", "width": "1%" }
            ]
        });
    };

    monitors.fetch({
        success: createTable,
        error: function ( _, xhr ) { alert(xhr.responseText); }
    });
});
