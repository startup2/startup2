'use strict'

index = require('express').Router()

index.get '/', (req, res)-> res.json {data: 'Welcome to CIAT Web Service'}
index.post '/', (req, res)-> res.json {data: 'Welcome to CIAT Web Service'}

module.exports = index