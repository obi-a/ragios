$(function() {

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

    var createTable = function( data ) {
        var monitorsList =
        $('#monitors-list-datatable').dataTable({
            "order": [ 0, 'desc' ],
            "data": cleanData(data),
            "columns": [
                { "data": "created_at_", "width": "16%" },
                { "data": "_id", "width": "31%" },
                { "data": "monitor", "width": "31%" },
                { "data": "every", "width": "1%" },
                { "data": "via", "width": "12%" },
                { "data": "plugin", "width": "8%" },
                { "data": "status_", "width": "1%" }
            ]
        });
    };

    ragios.getMonitors(
       createTable,
       function (xhr) {alert(xhr.responseText);}
    );

});
