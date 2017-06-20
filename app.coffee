'use strict'

# init express
app           = (require 'express')()
bodyParser    = require 'body-parser'
session       = require 'express-session'
store         = require('connect-oriento')(session)


# init helper
require './helper/initGlobal'
require './helper/initHelper'


# init database and session
log 'init database...'
orientjs = require 'orientjs'
database = orientjs {host:'localhost',port:2424,username:'root',password:'admin'}
global.db = database.use 'ciat'

# init middleware
app.use bodyParser.json()
app.use bodyParser.urlencoded({extended:true})
app.use session {
  secret: 'one for one'
  resave: false
  saveUninitialized: true
  cookie: {maxAge: 1000*60*10}
  store: new store {server: "host=localhost&port=2424&username=root&password=admin&db=ciat"}
}

# init view engine
app.set 'views', './view'
app.set 'view engine', 'pug'


# init router
app.use '/',        require './api/index'
app.use '/user',    require './api/user'
app.use '/company', require './api/company'

# start app
app.listen 3000, ->
  log 'server startup on 3000 port...'
