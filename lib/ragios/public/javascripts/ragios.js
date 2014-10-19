var ragios = {
    request : function( type, url, success, error, data ) {
        var options = {
            type: type,
            url: url,
            success: success,
            error: error,
            data: data || null
        }
        $.ajax(options);
    },

    restart : function(monitor_id, success, error) {
        this.request( "PUT", "/monitors/" + monitor_id + "?status=active", success, error );
    },

    stop : function(monitor_id, success, error) {
        this.request( "PUT", "/monitors/" + monitor_id + "?status=stopped", success, error );
    },

    test : function(monitor_id, success, error) {
        var data = {id: monitor_id};
        this.request( "POST", "/tests/", success, error, data);
    },

    add : function(data, success, error) {
        this.request("POST", "/monitors/", success, error, data);
    },

    delete : function(monitor_id, success, error) {
        this.request("DELETE", "/monitors/" + monitor_id, success, error);
    },

    update : function (monitor_id, data, success, error) {
        this.request("PUT", "/monitors/" + monitor_id, success, error, data);
    },

    find : function(monitor_id, success, error) {
        this.request( "GET", "/monitors/" + monitor_id, success, error)
    }
};

