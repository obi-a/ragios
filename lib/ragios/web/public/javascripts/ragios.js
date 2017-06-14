var ragios = {
    request : function(options) {
        $.ajax(options);
    },

    start : function(monitor_id, success, error) {
        this.request({
            type: "PUT",
            url: "/monitors/" + monitor_id + "?status=active",
            success: success,
            error: error
        });
    },

    stop : function(monitor_id, success, error) {
        this.request({
            type: "PUT",
            url: "/monitors/" + monitor_id + "?status=stopped",
            success: success,
            error: error
        });
    },

    test : function(monitor_id, success, error) {
        var data = {id: monitor_id};
        this.request({
            type: "POST",
            url: "/tests/",
            success: success,
            error: error,
            data: data
        });
    },

    create : function(data, success, error) {
        this.request({
            type: "POST",
            url: "/monitors/",
            success: success,
             error: error,
             data: data
        });
    },

    delete : function(monitor_id, success, error) {
        this.request({
            type: "DELETE",
            url: "/monitors/" + monitor_id,
            success: success,
            error: error
        });
    },

    delete_event : function(event_id, success, error) {
        this.request({
            type: "DELETE",
            url: "/events/" + event_id,
            success: success,
            error: error
        });
    },

    update : function (monitor_id, data, success, error) {
        this.request({
            type: "PUT",
            url: "/monitors/" + monitor_id,
            success: success,
            error: error,
            data: data,
            contentType: "application/json"
        });
    },

    find : function(monitor_id, success, error) {
        this.request({
            type: "GET",
            url: "/monitors/" + monitor_id,
            success: success,
            error: error,
        });
    },

    find_event : function(event_id, success, error) {
        this.request({
            type: "GET",
            url: "/events/" + event_id,
            success: success,
            error: error,
        });
    },

    getNotifications : function(monitor_id, startDate, endDate, success, error) {
        this.request({
            type: "GET",
            url: "/monitors/" + monitor_id + "/events_by_type/monitor.notification",
            data: {start_date: startDate, end_date: endDate },
            success: success,
            error: error
        });
    },

    getEvents : function(monitor_id, startDate, endDate, success, error) {
        this.request({
            type: "GET",
            url: "/monitors/" + monitor_id + "/events",
            data: {start_date: startDate, end_date: endDate },
            success: success,
            error: error
        });
    },

    getResultsByState : function( monitor_id, state, startDate, endDate, success, error) {
        this.request({
            type: "GET",
            url: "/monitors/" + monitor_id + "/events_by_state/" + state,
            data: {start_date: startDate, end_date: endDate },
            success: success,
            error: error
        });
    },

    getMonitors : function(success, error) {
        this.request({
            type: "GET",
            url: "/monitors",
            success: success,
            error: error
        });
    }

};

