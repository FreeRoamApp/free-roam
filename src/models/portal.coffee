_map = require 'lodash/map'
Fingerprint = require 'fingerprintjs'
getUuidByString = require 'uuid-by-string'

Environment = require '../services/environment'
PushService = require '../services/push'
config = require '../config'

if window?
  PortalGun = require 'portal-gun'

urlBase64ToUint8Array = (base64String) ->
  padding = '='.repeat((4 - (base64String.length % 4)) % 4)
  base64 = (base64String + padding).replace(/\-/g, '+').replace(/_/g, '/')
  rawData = window.atob(base64)
  outputArray = new Uint8Array(rawData.length)
  i = 0
  while i < rawData.length
    outputArray[i] = rawData.charCodeAt(i)
    i += 1
  outputArray

module.exports = class Portal
  constructor: ->
    if window?
      @portal = new PortalGun() # TODO: check isParentValid

      @appResumeHandler = null

  PLATFORMS:
    GAME_APP: 'game_app'
    WEB: 'web'

  setModels: (props) =>
    {@user, @pushToken, @modal, @installOverlay, @getAppDialog} = props
    null

  call: (args...) =>
    unless window?
      # throw new Error 'Portal called server-side'
      return console.log 'Portal called server-side'

    # FIXME FIXME: rm. HACK to fix sharing on old APK
    if args[0] is 'share.any'
      args[1].path = args[1].path.replace '/g/fortnitees', ''

    @portal.call args...
    .catch ->
      # if we don't catch, zorium freaks out if a portal call is in state
      # (infinite errors on page load/route)
      console.log 'missing portal call', args
      null

  callWithError: (args...) =>
    unless window?
      # throw new Error 'Portal called server-side'
      return console.log 'Portal called server-side'

    @portal.call args...

  listen: =>
    unless window?
      throw new Error 'Portal called server-side'

    @portal.listen()

    @portal.on 'auth.getStatus', @authGetStatus
    @portal.on 'share.any', @shareAny
    @portal.on 'env.getPlatform', @getPlatform
    @portal.on 'app.install', @appInstall
    @portal.on 'app.rate', @appRate
    @portal.on 'app.getDeviceId', @appGetDeviceId

    # fallbacks
    @portal.on 'app.onResume', @appOnResume

    # simulate app
    @portal.on 'deepLink.onRoute', @deepLinkOnRoute

    @portal.on 'top.onData', -> null
    @portal.on 'top.getData', -> null
    @portal.on 'push.register', @pushRegister

    @portal.on 'twitter.share', @twitterShare

    @portal.on 'networkInformation.onOnline', @networkInformationOnOnline
    @portal.on 'networkInformation.onOffline', @networkInformationOnOffline
    @portal.on 'networkInformation.onOnline', @networkInformationOnOnline


    @portal.on 'browser.openWindow', ({url, target, options}) ->
      window.open url, target, options


  ###
  @typedef AuthStatus
  @property {String} accessToken
  @property {String} userUuid
  ###

  ###
  @returns {Promise<AuthStatus>}
  ###
  authGetStatus: =>
    @model.user.getMe()
    .take(1).toPromise()
    .then (user) ->
      accessToken: user.uuid # Temporary
      userUuid: user.uuid

  shareAny: ({text, imageUrl, url}) =>
    ga? 'send', 'event', 'share_service', 'share_any'

    if url
      if text then text += ' '
      text += url
    @call 'twitter.share', {text}

  getPlatform: ({gameKey} = {}) =>
    userAgent = navigator.userAgent
    switch
      when Environment.isNativeApp(gameKey, {userAgent})
        @PLATFORMS.GAME_APP
      else
        @PLATFORMS.WEB

  isChrome: ->
    navigator.userAgent.match /chrome/i

  appRate: =>
    ga? 'send', 'event', 'native', 'rate'

    @call 'browser.openWindow',
      url: if Environment.isiOS() \
           then config.ITUNES_APP_URL
           else config.GOOGLE_PLAY_APP_URL
      target: '_system'

  appGetDeviceId: ->
    getUuidByString "#{new Fingerprint().get()}"

  appOnResume: (callback) =>
    if @appResumeHandler
      window.removeEventListener 'visibilitychange', @appResumeHandler

    @appResumeHandler = ->
      unless document.hidden
        callback()

    window.addEventListener 'visibilitychange', @appResumeHandler

  appInstall: ({group} = {}) =>
    iosAppUrl = config.IOS_APP_URL
    googlePlayAppUrl = config.GOOGLE_PLAY_APP_URL

    if Environment.isAndroid() and @isChrome()
      if @installOverlay.prompt
        prompt = @installOverlay.prompt
        @installOverlay.setPrompt null
      else
        @installOverlay.open()

    else if Environment.isiOS()
      @call 'browser.openWindow',
        url: iosAppUrl
        target: '_system'

    else if Environment.isAndroid()
      @call 'browser.openWindow',
        url: googlePlayAppUrl
        target: '_system'

    else
      @getAppDialog.open()

  twitterShare: ({text}) =>
    @call 'browser.openWindow', {
      url: "https://twitter.com/intent/tweet?text=#{encodeURIComponent text}"
      target: '_system'
    }

  deepLinkOnRoute: (fn) =>
    window.onRoute = (path) ->
      fn {path: path.replace('browser://', '/')}

  # facebookLogin: =>
  #   new Promise (resolve) =>
  #     FB.getLoginStatus (response) =>
  #       if response.status is 'connected'
  #         resolve {
  #           status: response.status
  #           facebookAccessToken: response.authResponse.accessToken
  #           id: response.authResponse.userID
  #         }
  #       else
  #         FB.login (response) ->
  #           resolve {
  #             status: response.status
  #             facebookAccessToken: response.authResponse.accessToken
  #             id: response.authResponse.userID
  #           }

  facebookShare: ({url}) ->
    FB.ui {
      method: 'share',
      href: url
    }

  pushRegister: ->
    PushService.registerWeb()
    # navigator.serviceWorker.ready.then (serviceWorkerRegistration) =>
    #   serviceWorkerRegistration.pushManager.subscribe {
    #     userVisibleOnly: true,
    #     applicationServerKey: urlBase64ToUint8Array config.VAPID_PUBLIC_KEY
    #   }
    #   .then (subscription) ->
    #     subscriptionToken = JSON.stringify subscription
    #     {token: subscriptionToken, sourceType: 'web'}
    #   .catch (err) =>
    #     serviceWorkerRegistration.pushManager.getSubscription()
    #     .then (subscription) ->
    #       subscription.unsubscribe()
    #     .then =>
    #       unless isSecondAttempt
    #         @pushRegister true
    #     .catch (err) ->
    #       console.log err

  networkInformationOnOnline: (fn) ->
    window.addEventListener 'online', fn

  networkInformationOnOffline: (fn) ->
    window.addEventListener 'offline', fn
