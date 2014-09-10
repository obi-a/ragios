var ragios = {
    confirm : function(message) {
        message = message || "Are you sure you want to continue?";
        return confirm(message);
    },

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
    }
};

