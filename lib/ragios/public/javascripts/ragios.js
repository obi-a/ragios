var ragios = {
    confirm : function(message) {
        message = message || "Are you sure you want to continue?";
        return confirm(message);
    },

    ajax : function(options) {
        return $.ajax(options);
    }
};

