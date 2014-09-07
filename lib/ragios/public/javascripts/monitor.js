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

    var request = function(type, url, data ) {
        var options = {
            type: type,
            url: url,
            success: success,
            error: error,
            data: data || null
        }
        ragios.ajax(options);
    }

    $( "#restart-button" ).click(function() {
        if( ragios.confirm("Are you sure you want to restart this monitor?") ) {
            var monitor_id = $("#_id").html();
            request( "PUT", "/monitors/" + monitor_id + "?status=active" );
        }
    });

    $( "#stop-button" ).click( function() {
        if( ragios.confirm("Are you sure you want to stop this monitor?") ) {
            var monitor_id = $("#_id").html();
            request( "PUT", "/monitors/" + monitor_id + "?status=stopped" );
        }
    });

    $( "#test-button" ).click( function() {
        if( ragios.confirm("Are you sure you want to test this monitor?") ) {
            var monitor_id = $("#_id").html();
            request( "POST", "/tests/", { id: monitor_id }  );
        }
    });
});
