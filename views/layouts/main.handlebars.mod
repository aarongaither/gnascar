<!DOCTYPE html>
<html lang="en">
<head>
  <meta http-equiv="Content-Type" content="text/html; charset=UTF-8"/>
  <meta name="viewport" content="width=device-width, initial-scale=1, maximum-scale=1.0"/>
  <title>GNASCAR</title>

  <link href="https://fonts.googleapis.com/icon?family=Material+Icons" rel="stylesheet">
  <link href="css/materialize.css" type="text/css" rel="stylesheet" media="screen,projection"/>
  <link href="css/style.css" type="text/css" rel="stylesheet" media="screen,projection"/>
  <script src="https://code.jquery.com/jquery-2.1.1.min.js"></script>
</head>
<body>
  <nav class="black lighten-1" role="navigation">
    <div class="nav-wrapper container">
      <a id="logo-container" href="/" class="brand-logo">
        <div class="line-block line-block-yellow-2"></div>
        <div class="line-block line-block-yellow-1"></div>
        <div class="line-block line-block-red-2"></div>
        <div class="line-block line-block-red-1"></div>
        <div class="line-block line-block-blue"></div>
        GNASCAR
      </a>

      <ul id="gnascar" class="dropdown-content">
        <li><a href="/gnascar_rosters" class="black-text">Rosters</a></li>
        <li class="divider"></li>
        <li><a href="/gnascar_rosters_html" class="black-text">Rosters HTML</a></li>
        <li class="divider"></li>
        <li><a href="/gnascar_standings" class="black-text">Standings</a></li>
      </ul>

      <ul id="nascar" class="dropdown-content">
        <li><a href="/nascar_driver_stats" class="black-text">Driver Stats</a></li>
        <li class="divider"></li>
        <li><a href="/nascar_loop_stats" class="black-text">Loop Stats</a></li>
        <li class="divider"></li>
        <li><a href="/nascar_race_stats" class="black-text">Race Stats</a></li>
        <li class="divider"></li>
        <li><a href="/nascar_schedule" class="black-text">Schedule</a></li>
      </ul>

      <ul class="right hide-on-med-and-down">
        <li><a class="dropdown-button" href="#!" data-activates="gnascar">GNASCAR<i class="material-icons right">arrow_drop_down</i></a></li>
        <li><a class="dropdown-button" href="#!" data-activates="nascar">NASCAR<i class="material-icons right">arrow_drop_down</i></a></li>
        <li><a href="/gallery">Gallery</a></li>
        <li><a href="/rules">Rules</a></li>
      </ul>

      <ul id="nav-mobile" class="side-nav">
        <li><a href="/gnascar_rosters">GNASCAR Rosters</a></li>
        <li><a href="/gnascar_standings">GNASCAR Standings</a></li>
        <li><a href="/nascar_driver_stats">NASCAR Driver Stats</a></li>
        <li><a href="/nascar_loop_stats">NASCAR Loop Stats</a></li>
        <li><a href="/nascar_race_stats">NASCAR Race Stats</a></li>
        <li><a href="/nascar_schedule">NASCAR Schedule</a></li>
        <li><a href="/gallery">Gallery</a></li>
        <li><a href="/rules">Rules</a></li>
      </ul>
      <a href="#" data-activates="nav-mobile" class="button-collapse"><i class="material-icons">menu</i></a>
    </div>
  </nav>
  {{{body}}}
<!--
  <footer class="page-footer black">
    <div class="container">
      <div class="row">
        <div class="col l6 s12">
          <h5 class="white-text">GNASCAR</h5>
          <p class="grey-text text-lighten-4">A highly opinionated NASCAR fantasy league, filled with (mostly) casual fans.</p>
        </div>
      </div>
    </div>
    <div class="footer-copyright">
      <div class="container">
      Made by <a class="orange-text text-lighten-3" href="https://github.com/aarongaither/" target="_blank">Gator Dad Racing</a>
      </div>
    </div>
  </footer>
-->
  <!--  Scripts-->
  <!-- <script src="js/materialize.js"></script> -->
  <script src="js/init.js"></script>

  </body>
</html>
