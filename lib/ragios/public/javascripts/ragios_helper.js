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

    init_add_field: function() {
        var self = this;
        $('#add-field-button').click(function () {
            var template = _.template($("#unnamed-field-template").html());
            $('#new-monitor-table').before(template);
            self.init_delete_field();
        });
    },

    init_delete_field: function() {
        $('.delete-field').click(function () {
            $(this).closest('tr')
                   .remove();

        });
    },

    getValues: function (selector, action) {
        return $(selector).map(action).get();
    }
};