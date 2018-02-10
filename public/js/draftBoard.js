let draftCount = 1;


$('.draft-btn').on('click', function() {
    console.log($(this).attr('data-value'));
    console.log(draftCount)
    $('#cell-' + draftCount).text($(this).attr('data-value'));
    draftCount++
    $(this).parent().remove();
})