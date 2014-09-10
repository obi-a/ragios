$(function() {
    //clean up/DRY up later
    var success = function ( xhr ) {
        $( "#message").attr('class', 'text-success');
        $( "#message" ).show( function() {
            $( this ).text( "Success!" );
        });
        $("#message").fadeOut(5000);
    };

    var error =  function ( xhr ) {
        $( "#message").attr('class', 'text-danger');
        $( "#message" ).show( function() {
            var response = $.parseJSON(xhr.responseText);
            $( this ).text( response.error );
        });
        $("#message").fadeOut(5000);
    };


    $( "#restart-button" ).click(function() {
        if( ragios.confirm("Are you sure you want to restart this monitor?") ) {
            var monitor_id = $("#_id").html();
            ragios.restart( monitor_id, success, error );
        }
    });

    $( "#stop-button" ).click( function() {
        if( ragios.confirm("Are you sure you want to stop this monitor?") ) {
            var monitor_id = $("#_id").html();
            ragios.stop(monitor_id, success, error);
        }
    });

    $( "#test-button" ).click( function() {
        if( ragios.confirm("Are you sure you want to test this monitor?") ) {
            var monitor_id = $("#_id").html();
            ragios.test(monitor_id, success, error);
        }
    });
});
