// Entry point for the build script in your package.json
import"./channels"
import "./controllers"

import Rails from "@rails/ujs"
import Turbolinks from "turbolinks"
import * as ActiveStorage from "@rails/activestorage"

Rails.start()
Turbolinks.start()
ActiveStorage.start()

// THIS IS MAKING jQuery AVAILABLE EVEN INSIDE Views FOLDER
// global.$ = require("jquery")

// require("aos_stuff")
import "./aos_stuff"
// require("jquery-ui")
// import "./jquery-ui"
// require("jquery.easy-autocomplete")
// import "./jquery.easy-autocomplete"
// require ("jquery")
// import "./jquery"
// require ("jquery_ujs")
// require ("jquery-ui/widgets/autocomplete")
// require("autocomplete-rails")
// import "./autocomplete-rails"
// require("jquery-ui")
// import "./jquery-ui"
// import "./bs-init"
// import "./bootstrap.min.js"
// import "./chart.min"
// import "./homepage"
// import "./style"

import * as bootstrap from "bootstrap"
