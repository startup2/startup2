'use strict'

company = require('express').Router()

########################################
# signup
########################################
company.get '/signup', (req, res)-> res.render 'company/signup'
company.post '/signup', (req, res)->
  unless req.body.companyID   then return res.status(400).json {data: MSG.INVALID_PARAMS}
  unless req.body.displayName then return res.status(400).json {data: MSG.INVALID_PARAMS}

  params =
    companyID:   req.body.companyID
    displayName: req.body.displayName

  sql = 'select * from company where companyID = :companyID'

  db.query(sql, {params: params}).then (ret)->
    if ret.length > 0 then return res.status(400).json {data: MSG.USERNAME_EXISTS}

    sql = 'insert into company (companyID, displayName) values (:companyID, :displayName)'
    db.query(sql, {params: params}).then (ret)->
      return res.json {data: MSG.SIGNUP_SUCCEED}
  .catch (err)->
    log 'err:', err
    res.status(500).json {data: MSG.SERVER_ERROR}

module.exports = company