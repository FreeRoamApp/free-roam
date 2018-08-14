require './polyfill'

_map = require 'lodash/map'
_mapValues = require 'lodash/mapValues'
z = require 'zorium'
log = require 'loga'
cookie = require 'cookie'
LocationRouter = require 'location-router'
Environment = require './services/environment'
socketIO = require 'socket.io-client/dist/socket.io.slim.js'
RxBehaviorSubject = require('rxjs/BehaviorSubject').BehaviorSubject
require 'rxjs/add/operator/do'

require './root.styl'

config = require './config'
RouterService = require './services/router'
PushService = require './services/push'
SemverService = require './services/semver'
App = require './app'
Model = require './models'
Portal = require './models/portal'

MAX_ERRORS_LOGGED = 5

###########
# LOGGING #
###########

if config.ENV is config.ENVS.PROD
  log.level = 'warn'

# Report errors to API_URL/log
errorsSent = 0
postErrToServer = (err) ->
  if errorsSent < MAX_ERRORS_LOGGED
    errorsSent += 1
    window.fetch config.API_URL + '/log',
      method: 'POST'
      headers:
        'Content-Type': 'text/plain' # Avoid CORS preflight
      body: JSON.stringify
        event: 'client_error'
        trace: null # trace
        error: String(err)
    .catch (err) ->
      console?.log 'logs post', err

log.on 'error', postErrToServer

oldOnError = window.onerror
window.onerror = (message, file, line, column, error) ->
  # if we log with `new Error` it's pretty pointless (gives error message that
  # just points to this line). if we pass the 5th argument (error), it breaks
  # on json.stringify
  # log.error error or new Error message
  err = {message, file, line, column}
  postErrToServer err

  if oldOnError
    return oldOnError arguments...

#################
# ROUTING SETUP #
#################

try
  navigator.serviceWorker?.register '/service_worker.js'
  .then (registration) ->
    PushService.setFirebaseServiceWorker registration
  .catch (err) ->
    console.log 'sw promise err', err
catch err
  console.log 'sw err', err

# start before dom has loaded
portal = new Portal()

init = ->
  initialCookies = cookie.parse(document.cookie)

  isOffline = new RxBehaviorSubject false
  isBackendUnavailable = new RxBehaviorSubject false
  currentNotification = new RxBehaviorSubject false

  io = socketIO config.API_HOST, {
    path: (config.API_PATH or '') + '/socket.io'
    # this potentially has negative side effects. firewalls could
    # potentially block websockets, but not long polling.
    # unfortunately, session affinity on kubernetes is a complete pain.
    # behind cloudflare, it seems to unevenly distribute load.
    # the libraries for sticky websocket sessions between cpus
    # also aren't great - it's hard to get the real ip sent to
    # the backend (easy as http-forwarded-for, hard as remote address)
    # and the only library that uses forwarded-for isn't great....
    # see kaiser experiments for how to pass source ip in gke, but
    # it doesn't keep session affinity (for now?) if adding polling
    transports: ['websocket']
  }
  fullLanguage = window.navigator.languages?[0] or window.navigator.language
  language = initialCookies?['language'] or fullLanguage?.substr(0, 2)
  unless language in config.LANGUAGES
    language = 'en'
  model = new Model {
    io, portal, language, initialCookies
    setCookie: (key, value, options) ->
      document.cookie = cookie.serialize \
        key, value, options
  }
  model.portal.listen()

  model.cookie.set(
    'resolution', "#{window.innerWidth}x#{window.innerHeight}"
  )

  onOnline = ->
    isOffline.next false
    console.log 'online invalidate'
    model.exoid.invalidateAll()
  onOffline = ->
    isOffline.next true

  router = new RouterService {
    model: model
    router: new LocationRouter()
    host: window.location.host
  }

  # alternative is to find a way for zorium to subscribe to observables
  # to not start with null
  # (flash with whatever obs data is on page going empty for 1 frame), then
  # render after a few ms
  root = document.getElementById('zorium-root').cloneNode(true)
  requests = router.getStream()
  app = new App {
    requests
    model
    router
    isOffline
    isBackendUnavailable
    currentNotification
  }
  $app = z app
  z.bind root, $app

  window.addEventListener 'beforeinstallprompt', (e) ->
    e.preventDefault()
    model.installOverlay.setPrompt e
    return false

  model.portal.call 'networkInformation.onOffline', onOffline
  model.portal.call 'networkInformation.onOnline', onOnline

  # model.reward.setup()

  if model.ad.isVisible() and Environment.isNativeApp 'freeroam'
    appVersion = Environment.getAppVersion 'freeroam'
    if appVersion
      admobMediationSupported = SemverService.gte(appVersion, '1.2.4')
      nativeAdsSupported = SemverService.gte(appVersion, '1.2.3')
      # TODO: implement by group key, not app info
      isFortniteApp = Environment.isGroupApp 'fortnite'
      setTimeout ->
        if Environment.isiOS() and Environment.isGroupApp 'nickatnyte'
          adId = 'ca-app-pub-9043203456638369/2146180874'
        else if Environment.isGroupApp 'nickatnyte'
          adId = 'ca-app-pub-9043203456638369/3407291659'
        else if Environment.isiOS()
          adId = 'ca-app-pub-9043203456638369/5699503414'
        else if isFortniteApp and Math.random() > 0.50
          adId = 'ca-app-pub-4313642096020551/3038303833'
        else
          adId = 'ca-app-pub-9043203456638369/2454362164'

        portalCall = if admobMediationSupported \
                     then 'admob.showBanner'
                     else 'heyzap.showBanner'

        model.portal?.call portalCall, {
          position: 'bottom'
          overlap: false
          adId: adId
        }
      , 1000


  # model.portal.call 'admob.prepareInterstitial', {
  #   adid: '' # FIXME
  # }

  model.portal.call 'app.onBack', ->
    router.back({fromNative: true})

  # iOS scrolls past header
  # model.portal.call 'keyboard.disableScroll'
  # model.portal.call 'keyboard.onShow', ({keyboardHeight}) ->
  #   model.window.setKeyboardHeight keyboardHeight
  # model.portal.call 'keyboard.onHide', ->
  #   model.window.setKeyboardHeight 0

  routeHandler = (data) ->
    data ?= {}
    {path, query, source, _isPush, _original, _isDeepLink} = data

    if _isDeepLink
      return # FIXME only for fb login links

    # ios fcm for now. TODO: figure out how to get it a better way
    if not path and typeof _original?.additionalData?.path is 'string'
      path = JSON.parse _original.additionalData.path

    if query?.accessToken?
      model.auth.setAccessToken query.accessToken

    if _isPush and _original?.additionalData?.foreground
      model.exoid.invalidateAll()
      if Environment.isiOS() and Environment.isNativeApp 'freeroam'
        model.portal.call 'push.setBadgeNumber', {number: 0}

      currentNotification.next {
        title: _original?.additionalData?.title or _original.title
        message: _original?.additionalData?.message or _original.message
        type: _original?.additionalData?.type
        data: {path}
      }
    else if path?
      ga? 'send', 'event', 'hit_from_share', 'hit', path
      if path?.key
        router.go path.key, path.params
      else if path # legacy
        router.goPath path
    # else
    #   router.go()

    if data.logEvent
      {category, action, label} = data.logEvent
      ga? 'send', 'event', category, action, label

  model.portal.call 'top.onData', (e) ->
    routeHandler e

  start = Date.now()
  (if Environment.isNativeApp 'freeroam'
    portal.call 'top.getData'
  else
    Promise.resolve null)
  .then routeHandler
  .catch (err) ->
    log.error err
    router.go()
  .then ->
    model.portal.call 'app.isLoaded'

    # untilStable hangs many seconds and the
    # timeout (200ms) doesn't actually work
    if model.wasCached()
      new Promise (resolve) ->
        # give time for exoid combinedStreams to resolve
        # (dataStreams are cached, combinedStreams are technically async)
        setTimeout resolve, 300
        # z.untilStable $app, {timeout: 200} # arbitrary
    else
      null
  .then ->
    requests.do(({path}) ->
      if window?
        ga? 'send', 'pageview', path
    ).subscribe()

    # nextTick prevents white flash
    setTimeout ->
      $$root = document.getElementById 'zorium-root'
      $$root.parentNode.replaceChild root, $$root

  # window.addEventListener 'resize', app.onResize
  # model.portal.call 'orientation.onChange', app.onResize

  PushService.init {model}
  (if Environment.isNativeApp('freeroam')
    PushService.register {model, isAlwaysCalled: true}
  else
    Promise.resolve null)
  .then ->
    model.portal.call 'app.onResume', ->
      # console.log 'resume invalidate'
      model.exoid.invalidateAll()
      model.window.resume()
      if Environment.isiOS() and Environment.isNativeApp 'freeroam'
        model.portal.call 'push.setBadgeNumber', {number: 0}

if document.readyState isnt 'complete' and
    not document.getElementById 'zorium-root'
  document.addEventListener 'DOMContentLoaded', init
else
  init()
#############################
# ENABLE WEBPACK HOT RELOAD #
#############################

if module.hot
  module.hot.accept()
