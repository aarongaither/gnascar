const router = require('express').Router();
const drivers = require('../model/drivers');

router.get('/', (req, res) => res.render('home'));
router.get('/draft-list', (req, res) => res.render('draftList', {drivers,}));
router.get('/driver-standings', (req, res) => res.render('driverStandings'));
router.get('/team-standings', (req, res) => res.render('teamStandings'));
router.get('/rules', (req, res) => res.render('rules'));

module.exports = router;