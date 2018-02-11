let draftCount = 1;

const draftOrder = [
    'Hollywood Highlife',
    'Julian Gangsta',
    'SMiB',
    'Baby Got Track',
    'Redneck Ghoster',
    'Chasing Cletus',
    'Gator Dad',
    'Hot Johnson',
    'Everyone Loves Busch',
    'Upfront',
];

const keepers = [
    {cell: '26', driver: 'Chase Elliott', car_no: '9'},
    {cell: '27', driver: 'Kyle Larson', car_no: '42'},
    {cell: '28', driver: 'Jimmie Johnson', car_no: '48'},
    {cell: '29', driver: 'Kyle Busch', car_no: '18'},
    {cell: '30', driver: 'Martin Truex Jr.', car_no: '78'}
];


for (let i = 0; i < keepers.length; i++) {
    const cur = keepers[i];
    $('#car-'+cur.car_no).remove();
    $('#cell-'+cur.cell).text(cur.driver);
}

function updatePage() {
    const round = Math.ceil(draftCount / 10);
    const position = draftCount % 10 || 10;
    const current = draftOrder[position - 1];
    const onDeck = position >= draftOrder.length ? draftOrder[0] : draftOrder[position];
    
    $('#round').text(round);
    $('#position').text(position);
    $('#current').text(current);
    $('#ondeck').text(onDeck);
};

updatePage();

$('.draft-btn').on('click', function() {
    $('#cell-' + draftCount).text($(this).attr('data-value'));

    draftCount++
    updatePage();

    $(this).parent().remove();
});