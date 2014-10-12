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
    }
};