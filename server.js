const express = require("express");
const path = require("path");
const exphbs = require("express-handlebars");
const routes = require('./controller/routes');

const app = express();
const port = process.env.PORT || 80;

app.get('/', (req, res) => res.render('home'));

app.engine("handlebars", exphbs({ defaultLayout: "main" }));
app.set("view engine", "handlebars");

app.use('/', routes);
app.use(express.static(path.join(__dirname, 'public')));

// Starts the server to begin listening
// =============================================================
app.listen(port, () => console.log("App listening on PORT " + port));