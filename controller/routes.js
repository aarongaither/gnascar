const router = require('express').Router();
const readdirSync = require('fs').readdirSync;
const drivers = require('../model/drivers');
const cletusPics = readdirSync('./public/cletus-pics/');

router.get('/', (req, res) => res.render('home'));
router.get('/gallery', (req, res) => res.render('gallery', { cletusPics, }))
router.get('/gnascar_rosters', (req, res) => res.render('gnascar_rosters'));
router.get('/gnascar_rosters_html', (req, res) => res.render('gnascar_rosters_html'));
router.get('/gnascar_standings', (req, res) => res.render('gnascar_standings'));
router.get('/nascar_driver_stats', (req, res) => res.render('nascar_driver_stats'));
router.get('/nascar_loop_stats', (req, res) => res.render('nascar_loop_stats'));
router.get('/nascar_race_stats', (req, res) => res.render('nascar_race_stats'));
router.get('/nascar_schedule', (req, res) => res.render('nascar_schedule'));
router.get('/rules', (req, res) => res.render('rules'));
module.exports = router;
