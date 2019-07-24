express = require 'express'
_every = require 'lodash/every'
_values = require 'lodash/values'
_defaults = require 'lodash/defaults'
_mapValues = require 'lodash/mapValues'
_map = require 'lodash/map'
compress = require 'compression'
helmet = require 'helmet'
z = require 'zorium'
Promise = require 'bluebird'
cookieParser = require 'cookie-parser'
fs = require 'fs'
socketIO = require 'socket.io-client'
HttpHash = require 'http-hash'
RxBehaviorSubject = require('rxjs/BehaviorSubject').BehaviorSubject
require 'rxjs/add/operator/do'
require 'rxjs/add/operator/take'
require 'rxjs/add/operator/toPromise'
require 'rxjs/add/operator/publishReplay'
require 'rxjs/add/operator/concat'

config = require './src/config'
gulpPaths = require './gulp_paths'
App = require './src/app'
Model = require './src/models'
RouterService = require './src/services/router'
request = require './src/services/request'

MIN_TIME_REQUIRED_FOR_HSTS_GOOGLE_PRELOAD_MS = 10886400000 # 18 weeks
HEALTHCHECK_TIMEOUT = 200
RENDER_TO_STRING_TIMEOUT_MS = 1200
BOT_RENDER_TO_STRING_TIMEOUT_MS = 4500

# memwatch = require 'memwatch-next'
#
# hd = undefined
# snapshotTaken = false
# # memwatch.on 'stats', (stats) ->
# console.log 'stats:', stats
# if snapshotTaken is false
#   hd = new (memwatch.HeapDiff)
#   snapshotTaken = true
#   setTimeout ->
#     diff = hd.end()
#     console.log(JSON.stringify(diff, null, '\t'))
#   , 15000
# else
#   # diff = hd.end()
#   snapshotTaken = false
#   # console.log(JSON.stringify(diff, null, '\t'))


app = express()
app.use compress()

# CSP is disabled because kik lacks support
# frameguard header is disabled because Native app frames page
app.disable 'x-powered-by'
app.use helmet.xssFilter()
app.use helmet.hsts
  # https://hstspreload.appspot.com/
  maxAge: MIN_TIME_REQUIRED_FOR_HSTS_GOOGLE_PRELOAD_MS
  includeSubDomains: true # include in Google Chrome
  preload: true # include in Google Chrome
  force: true
app.use helmet.noSniff()
app.use cookieParser()

app.use '/healthcheck', (req, res, next) ->
  Promise.all [
    Promise.cast(request(config.API_URL + '/ping'))
      .timeout HEALTHCHECK_TIMEOUT
      .reflect()
  ]
  .spread (api) ->
    result =
      api: api.isFulfilled()

    isHealthy = _every _values result
    if isHealthy
      res.json {healthy: isHealthy}
    else
      res.status(500).json _defaults {healthy: isHealthy}, result
  .catch next

app.use '/sitemap.txt', (req, res, next) ->
  request(config.API_URL + '/sitemap', {json: true})
  .then (paths) ->
    res.setHeader 'Content-Type', 'text/plain'
    res.send (_map paths, (path) -> "https://#{config.HOST}#{path}").join "\n"

app.use '/ping', (req, res) ->
  res.send 'pong'

app.use '/setCookie', (req, res) ->
  res.statusCode = 302
  res.cookie 'first_cookie', '1', {maxAge: 3600 * 24 * 365 * 10}
  res.setHeader 'Location', decodeURIComponent req.query?.redirect_url
  res.end()

# app.get '/manifest.json', (req, res, next) ->
#   try
#     res.setHeader 'Content-Type', 'application/json'
#     res.send new Buffer(req.query.data, 'base64').toString()
#   catch err
#     next err


if config.ENV is config.ENVS.PROD
# service_worker.js max-age modified in load-balancer
then app.use express.static(gulpPaths.dist, {maxAge: '4h'})
else app.use express.static(gulpPaths.build, {maxAge: '4h'})

stats = JSON.parse \
  fs.readFileSync gulpPaths.dist + '/stats.json', 'utf-8'

app.use (req, res, next) ->
  hasSent = false
  userAgent = req.headers['user-agent']
  host = req.headers.host
  accessToken = req.query.accessToken

  io = socketIO config.API_HOST, {
    path: (config.API_PATH or '') + '/socket.io'
    timeout: 5000
    transports: ['websocket']
  }
  fullLanguage = req.headers?['accept-language']
  language = req.query?.lang or
    req.cookies?['language'] or
    fullLanguage?.substr(0, 2)
  unless language in config.LANGUAGES
    language = 'en'
  model = new Model {
    io, language, host
    initialCookies: req.cookies
    serverHeaders: req.headers
    setCookie: (key, value, options) ->
      res.cookie key, value, options
  }
  router = new RouterService {
    router: null
    model: model
    host: host
  }
  requests = new RxBehaviorSubject(req)

  # FIXME: hardcoded redirect from mvg.freeroam.app (midwest vanlife gathering)
  if router.getSubdomain() in ['mvg', 'vldnv']
    res.statusCode = 301
    res.setHeader 'Location', decodeURIComponent(
      "https://freeroam.app/g/#{router.getSubdomain()}/chat"
    )
    return res.end()

  # for client to access
  model.cookie.set(
    'ip'
    req.headers?['x-forwarded-for'] or req.connection.remoteAddress
  )

  if config.ENV is config.ENVS.PROD
    scriptsCdnUrl = config.SCRIPTS_CDN_URL
    bundlePath = "#{scriptsCdnUrl}/bundle_#{stats.hash}_#{language}.js"
    bundleCssPath = "#{scriptsCdnUrl}/bundle_#{stats.hash}.css"
  else
    bundlePath = null
    bundleCssPath = null

  serverData = {req, res, bundlePath, bundleCssPath}
  userAgent = req.headers?['user-agent']
  isFacebookCrawler = userAgent?.indexOf('facebookexternalhit') isnt -1 or
      userAgent?.indexOf('Facebot') isnt -1
  isOtherBot = userAgent?.indexOf('bot') isnt -1
  isCrawler = isFacebookCrawler or isOtherBot
  start = Date.now()

  onError = (err) ->
    io.disconnect()
    model.dispose()
    disposable?.unsubscribe()
    if err?.message?.indexOf('Timeout') is -1
      console.log err
    if err.html
      hasSent = true
      if err.html.indexOf('<head>') is -1
        res.redirect 302, '/'
      else
        res.send '<!DOCTYPE html>' + err.html
    else
      if config.ENV is config.ENVS.PROD and req.path isnt '/'
        res.redirect 302, '/'
      else
        next err

  try
    z.renderToString new App({requests, model, serverData, router, isCrawler}), {
      timeout: if isCrawler \
               then BOT_RENDER_TO_STRING_TIMEOUT_MS
               else RENDER_TO_STRING_TIMEOUT_MS
    }
    .then (html) ->
      io.disconnect()
      model.dispose()
      disposable = null
      hasSent = true
      if html.indexOf('<head>') is -1
        res.redirect 302, '/'
      else
        res.send '<!DOCTYPE html>' + html
    .catch onError
  catch err
    onError err

module.exports = app
