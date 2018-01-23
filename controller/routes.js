const router = require('express').Router();

router.get('/', (req, res) => res.render('home'));

router.get('/draft-list', (req, res) => res.render('draftList'));
router.get('/driver-standings', (req, res) => res.render('driverStandings'));
router.get('/team-standings', (req, res) => res.render('teamStandings'));
router.get('/rules', (req, res) => res.render('rules'));

module.exports = router;