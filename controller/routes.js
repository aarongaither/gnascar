const router = require('express').Router();
const readdirSync = require('fs').readdirSync;
const drivers = require('../model/drivers');
const cletusPics = readdirSync('./public/cletus-pics/');

router.get('/', (req, res) => res.render('home'));
// router.get('/draft-list', (req, res) => res.render('draftList', {drivers,}));
// router.get('/draft-board', (req, res) => res.render('draftBoard', {drivers,}));
router.get('/rules', (req, res) => res.render('rules'));
router.get('/roster-2017', (req, res) => res.render('roster-2017'));
router.get('/roster-2018', (req, res) => res.render('roster-2018'));
router.get('/summary-2017', (req, res) => res.render('summary-2017'));
router.get('/summary-2018', (req, res) => res.render('summary-2018'));
router.get('/stats-2018', (req, res) => res.render('stats-2018'));
router.get('/adventures-of-cletus', (req, res) => res.render('cletus', { cletusPics, }))
module.exports = router;