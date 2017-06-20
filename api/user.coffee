'use strict'

user = require('express').Router()

########################################
# helper:
#   isExistsUsername
#   isExistsMobile
#   isLogin
#   session
########################################
user.get '/isExistsUsername', (req, res)-> res.render 'user/isExistsUsername'
user.post '/isExistsUsername', (req, res)->
  unless req.body.username then return res.status(400).json {data: MSG.INVALID_PARAMS}

  params = {username: req.body.username}
  sql = 'select * from user where username = :username'

  db.query(sql, {params: params}).then (ret)->
    if ret.length == 0 then return res.json {data: false}
    res.json {data: true}
  .catch (err)->
    log err, 'err'
    res.status(500).json {data: MSG.SERVER_ERROR}


user.get '/isExistsMobile', (req, res)-> res.render 'user/isExistsMobile'
user.post '/isExistsMobile', (req, res)->
  unless req.body.mobile then return res.status(400).json {data: MSG.INVALID_PARAMS}

  params = {mobile: req.body.mobile}
  sql = 'select * from user where mobile = :mobile'

  db.query(sql, {params: params}).then (ret)->
    if ret.length == 0 then return res.json {data: false}
    res.json {data: true}
  .catch (err)->
    log 'err:', err
    res.status(500).json {data: MSG.SERVER_ERROR}


user.get '/isLogin', (req, res)-> res.render 'user/isLogin'
user.post '/isLogin', (req, res)->
  unless req.body.username    then return res.status(400).json {data: MSG.INVALID_PARAMS}

  params = {username: req.body.username, sessionID: req.sessionID}
  sql = 'select * from user where username = :username'

  db.query(sql, {params: params}).then (user)->
    if user.length == 0 then return res.status(400).json {data: MSG.INVALID_LOGIN_INFO}

    user = user[0]

    if user.sessionID is req.sessionID then res.json {data: MSG.LOGIN_SUCCEED}
    else res.status(400).json {data: MSG.INVALID_SESSION_ID}
  .catch (err)->
    log 'err:', err
    res.status(500).json {data: MSG.SERVER_ERROR}

user.get '/session', (req, res)-> res.render 'user/session'
user.post '/session', (req, res)->
  unless req.body.username then return res.status(400).json {data: MSG.INVALID_PARAMS}
  unless req.session?.username? then return res.status(400).json {data: MSG.LOGIN_REQUIRED}

  res.json {data: req.session}


########################################
# signup, login, logout, profile, state
########################################
user.get '/', (req, res)->
  unless req.session?.username? then return res.status(400).json {data: MSG.LOGIN_REQUIRED}
  username = req.query.username
  if username then return res.json {data: username}

  sql = 'select username, displayName, mobile, birthdate, sex, state from user'
  db.query(sql).then (user)->
    res.json {data: user}
  .catch (err)->
    log 'error=', err
    res.status(500).json {data: MSG.SERVER_ERROR}

user.get '/signup', (req, res)-> res.render 'user/signup'
user.post '/signup', (req, res)->
  unless req.body.username    then return res.status(400).json {data: MSG.INVALID_PARAMS}
  unless req.body.password    then return res.status(400).json {data: MSG.INVALID_PARAMS}
  unless req.body.mobile      then return res.status(400).json {data: MSG.INVALID_PARAMS}
  unless req.body.displayName then return res.status(400).json {data: MSG.INVALID_PARAMS}

  params = {username: req.body.username}
  sql = 'select * from user where username=:username'
  db.query(sql, {params: params}).then (user)->
    if user.length > 0 then return res.status(400).json {data: MSG.USERNAME_EXISTS}

    db.query('select * from company where companyID="DEFAULT"').then (company)->
      params =
        username:     req.body.username
        password:     req.body.password
        displayName:  req.body.displayName
        mobile:       req.body.mobile
        birthdate:    req.body.birthdate
        sessionID:    null
        companyID:    company[0]['@rid'].toString()
        state:        USER_STATE.CONFIRM_REQUIRED
        class:        USER_CLASS.MEMBER

      sql = '''insert into user set
        username=:username,
        password=:password,
        displayName=:displayName,
        mobile=:mobile,
        birthdate=:birthdate,
        sessionID=:sessionID,
        companyID=:companyID,
        createdAt=SYSDATE(),
        state=:state,
        class=:class
        '''

      db.query(sql, {params: params}).then (result)->
        res.json {data: MSG.SIGNUP_SUCCEED}
  .catch (err)->
    log 'err:', err
    res.status(500).json {data: MSG.SERVER_ERROR}


user.get '/login', (req, res)-> res.render 'user/login'
user.post '/login', (req, res)->
  unless req.body.username then return res.status(400).json {data: MSG.INVALID_PARAMS}
  unless req.body.password then return res.status(400).json {data: MSG.INVALID_PARAMS}

  # check user confirmed
  params = {username: req.body.username}
  sql = 'select * from user where username=:username'
  db.query(sql, {params: params}).then (user)->
    unless user.length is 1 then return res.status(400).json {data: MSG.INVALID_PARAMS}
    if user[0]['state'] is USER_STATE.CONFIRM_REQUIRED
      return res.status(400).json {data: MSG.USER_CONFIRM_REQUIRED}

    params = {username: req.body.username, password: req.body.password}
    sql = 'select * from user where username = :username and password = :password'

    db.query(sql, {params: params}).then (user)->
      if user.length == 0 then return res.status(400).json {data: MSG.INVALID_LOGIN_INFO}

      params = {sessionID: req.sessionID, username: req.body.username}
      sql = 'update user set sessionID = :sessionID where username = :username'

      db.query(sql, {params: params}).then (ret)->
        req.session.rid         = user[0]['@rid']
        req.session.username    = user[0]['username']
        req.session.displayName = user[0]['displayName']
        req.session.mobile      = user[0]['mobile']
        req.session.birthdate   = user[0]['birthdate']
        req.session.sessionID   = req.sessionID
        req.session.companyID   = user[0]['companyID']
        req.session.createdAt   = user[0]['createdAt']
        req.session.state       = user[0]['state']
        req.session.class       = user[0]['class']
        req.session.save (err)->
          if err then return res.status(400).json {data: MSG.SERVER_ERROR}
          res.json {data: MSG.LOGIN_SUCCEED}
    .catch (err)->
      log 'err:', err
      res.status(500).json {data: MSG.SERVER_ERROR}


user.get '/logout', (req, res)-> res.render 'user/logout'
user.post '/logout', (req, res)->
  unless req.body.username then return res.status(400).json {data: MSG.INVALID_PARAMS}
  unless req.session?.username? then return res.status(400).json {data: MSG.LOGIN_REQUIRED}

  delete req.session.username

  req.session.save (err)->
    if err then return res.status(500).json {data: MSG.SERVER_ERROR}
    res.json {data: MSG.LOGOUT_SUCCESS}


user.get '/profile', (req, res)-> res.render 'user/profile'
user.post '/profile', (req, res)->
  unless req.body.username then return res.status(400).json {data: MSG.INVALID_PARAMS}
  unless req.session?.username? then return res.status(400).json {data: MSG.LOGIN_REQUIRED}

  params = {username: req.body.username}
  sql = 'select * from user where username=:username'

  db.query(sql, {params: params}).then (user)->
    if user.length == 0 then return res.status(400).json {data: MSG.INVALID_PARAMS}

    params = {username: req.body.username}
    sql = 'select * from user where username=:username'

    db.query(sql, {params: params}).then (user)->
      profile = {}
      profile.rid         = user[0]['@rid']
      profile.username    = user[0]['username']
      profile.displayName = user[0]['displayName']
      profile.mobile      = user[0]['mobile']
      profile.birthdate   = user[0]['birthdate']
      profile.companyID   = user[0]['companyID']
      profile.createdAt   = user[0]['createdAt']
      profile.state       = user[0]['state']
      profile.class       = user[0]['class']

      res.json {data: profile}
    .catch (err)->
      log 'err:', err
      res.status(500).json {data: MSG.SERVER_ERROR}

user.get '/state', (req, res)-> res.render 'user/state'
user.post '/state', (req, res)->
  unless req.body.username    then return res.status(400).json {data: MSG.INVALID_PARAMS}
  unless req.body.state       then return res.status(400).json {data: MSG.INVALID_PARAMS}
  unless req.session?.username? then return res.status(400).json {data: MSG.LOGIN_REQUIRED}

  params = {username: req.body.username, state: req.body.state}
  sql = 'update user set state=:state where username=:username'

  db.query(sql, {params:params}).then ->
    res.json {data: MSG.USER_STATE_UPDATED}
  .catch (err)->
    log 'err:', err
    res.status(500).json {data: MSG.SERVER_ERROR}


########################################
# user profile
########################################


module.exports = user