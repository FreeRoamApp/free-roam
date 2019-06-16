#!/usr/bin/env coffee

app = require '../server'
config = require '../src/config'

if config.DEV_USE_HTTPS
  https = require 'https'
  fs = require 'fs'
  privateKey  = fs.readFileSync './bin/fr-dev.key'
  certificate = fs.readFileSync './bin/fr-dev.crt'
  credentials = {key: privateKey, cert: certificate}
  httpsServer = https.createServer credentials, app

app.all '/*', (req, res, next) ->
  res.header(
    'Access-Control-Allow-Origin', config.WEBPACK_DEV_URL
  )
  res.header 'Access-Control-Allow-Headers', 'X-Requested-With'
  next()

if config.DEV_USE_HTTPS
  httpsServer.listen config.PORT, ->
    console.log 'Listening (https) on port %d', config.PORT
else
  app.listen config.PORT, ->
    console.log
      event: 'dev_server_start'
      message: "Listening on port #{config.PORT}"
