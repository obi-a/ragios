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
      try{
        return _.reduce(_.pairs(result), function( memo, pair ) {
            return memo.toString() + "\n" + pair;
        });
      } catch (e) { return ""; }
    },

    formatDate: function (date) {
        return moment(date).format('llll');
    },

    formatDateSmall: function (date) {
        return moment(date).format('L LT');
    },

    formatEventId: function (event_id) {
        return '<a href="/admin/events/' + event_id + '" data-toggle="modal" data-target="#event-modal">' + event_id + '</a>';
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
        } else if(state === "resolved") {
            return '<span class="label label-success">resolved</span>'
        } else if(state === "failed") {
            return '<span class="label label-danger">failed</span>'
        } else if (state === "error")  {
            return '<span class="label label-default">error</span>'
        } else if (state === "stopped")  {
            return '<span class="label label-warning">stopped</span>'
        } else if (state === "started")  {
            return '<span class="label label-primary">started</span>'
        } else {
            return '<span class="label label-primary">' + state + '</span>'
        }
    },

    linkTo: function( text, uri) {
       var anchor =  _.template('<a href="<%= uri %>"><%= text %></a>');
       return anchor({uri: uri, text: text});
    }
};