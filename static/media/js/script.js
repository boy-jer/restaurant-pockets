$(function () {
    $( "#datepicker" ).datepicker();

    $("#add").click(function () {
        var inputs = $(".table_size");
        var newElem = $(inputs[0]).clone();
        var last = $(inputs[inputs.length - 1]);
        last.after(newElem);
    });


    
});