$(function() {
    //clean up/DRY up later
    var success = function () {
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

    var getMonitorId = function () {
        return $("#_id").html();
    };

    $('#myTab a').click(function (e) {
        e.preventDefault();
        $(this).tab('show');
    })

    $( "#restart-button" ).click(function() {
        if( ragios.confirm("Are you sure you want to restart this monitor?") ) {
            ragios.restart( getMonitorId(), success, error );
        }
    });

    $( "#stop-button" ).click( function() {
        if( ragios.confirm("Are you sure you want to stop this monitor?") ) {
            ragios.stop( getMonitorId(), success, error );
        }
    });

    $( "#test-button" ).click( function() {
        if( ragios.confirm("Are you sure you want to test this monitor?") ) {
            ragios.test( getMonitorId(), success, error);
        }
    });

    $( "#refresh-current-state").click( function() {
        var refreshStateSuccess = function ( response ) {
            $.each(response, function (i, item) {
                $('<tr>').append(
                $('<td>').text(item.rank),
                $('<td>').text(item.content),
                $('<td>').text(item.UID)).appendTo('#records_table');
            });
        };
        var refreshStateError = function () {};
        ragios.getCurrentState( getMonitorId(), refreshStateSuccess, refreshStateError );
    });
});
