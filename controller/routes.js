const router = require('express').Router();
const drivers = require('../model/drivers');

router.get('/', (req, res) => res.render('home'));
router.get('/draft-list', (req, res) => res.render('draftList', {drivers,}));
router.get('/driver-standings', (req, res) => res.render('driverStandings'));
router.get('/team-standings', (req, res) => res.render('teamStandings'));
router.get('/rules', (req, res) => res.render('rules'));
router.get('/roster-2017', (req, res) => res.render('roster-2017'));
router.get('/roster-2018', (req, res) => res.render('roster-2018'));
router.get('/summary-2017', (req, res) => res.render('summary-2017'));
router.get('/summary-2018', (req, res) => res.render('summary-2018'));

module.exports = router;