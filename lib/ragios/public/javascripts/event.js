$(function() {

    var getEventId = _.memoize(function () {
        return $("#event-id").html().trim();
    });

    var $eventModal = $("#event-modal")

    var Util = {
        init: function () {
            this.message = $("#modal-message");
            _.templateSettings = {
                interpolate: /\{\{(.+?)\}\}/g
            };
            this.messageTemplate = _.template( $('#modal-message-template').html() );
        },
        error: function ( xhr ) {
            var response = $.parseJSON(xhr.responseText);
            Util.message.append(
               Util.messageTemplate({message: "Error", alert: "danger", response: JSON.stringify(response)})
            );
        }
    }

   var RagiosEvent  = {
        init: function () {
            this.createEditor();
            this.find();
        },
        createEditor: function () {
            var editorOptions = {
                mode: 'view',
                error: function (err) {
                    console.log(err.toString());
                }
            };

            this.editor = new JSONEditor(
                document.getElementById("event-editor"),
                editorOptions
            );
        },
        render: function (data) {
            RagiosEvent.editor.set(data);
        },
        find: function () {
            ragios.find_event( getEventId(), this.render, Util.error );
        },
        delete: function () {
            if( ragiosHelper.confirm("Are you sure you want to delete this event?") ) {
                var deleteSuccess = function () {
                    $eventModal.modal('toggle');
                };
                ragios.delete_event( getEventId(), deleteSuccess, Util.error );
            }
        }
    }

    $( "#delete-event-button" ).on("click", function() { RagiosEvent.delete(); });

    Util.init();
    RagiosEvent.init();
});
