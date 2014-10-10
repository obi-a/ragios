$(function() {
    $('#add-field-button').click(function () {
        $('#new-monitor-table').append('<tr id="' + _.uniqueId('table_row_') + '" ><td><span class="delete-field glyphicon glyphicon-remove" data-toggle="tooltip" data-placement="top" title="Delete field"></span> <input id="monitor" style="width: 96%;" type="text"></td><td ><input id="unamed" style="width: 100%;" type="text"></td></tr>');
        $('.delete-field').click(function () {
            $(this).closest('tr')
                   .remove();

        });
    });

    $('#update-button').click( function () {
        //console.log($("#monitor").val());
        getMonitorFromForm();
    });

    var element = document.getElementById('editor_holder');

    var editor = new JSONEditor(element, {
        schema: {}
    });

    JSONEditor.defaults.options.theme = 'bootstrap2';


    var getMonitorFromForm = function () {

    };
    var getMonitorFromJsonEditor = function () {

    };
});
