var ragiosHelper = {

    confirm : function( message ) {
        message = message || "Are you sure you want to continue?";
        return confirm( message );
    },

    redirect_to: function( path ) {
        window.location.replace( path );
    },

    back_to_index: function() {
        this.redirect_to( "/admin/index" );
    },

    formatResults: function (result) {
        return _.reduce(_.pairs(result), function( memo, pair ) {
            return memo.toString() + "\n" + pair;
        });
    },

    formatDate: function (date) {
        return moment(date).format('llll');
    },

    formatDateSmall: function (date) {
        return moment(date).format('L LT');
    },

    formatStatus: function (status) {
        if(status === "active") {
            return '<span class="label label-primary">active</span>'
        } else if(status === "stopped") {
            return '<span class="label label-warning">stopped</span>'
        }
    },

    formatState: function (state) {
        if(state === "passed") {
            return '<span class="label label-success">passed</span>'
        } else if(state === "failed") {
            return '<span class="label label-danger">failed</span>'
        } else if (state === "error")  {
            return '<span class="label label-default">error</span>'
        }
    },

    linkTo: function( text, uri) {
       var anchor =  _.template('<a href="<%= uri %>"><%= text %></a>');
       return anchor({uri: uri, text: text});
    }
};