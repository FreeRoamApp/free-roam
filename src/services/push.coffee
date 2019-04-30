Environment = require '../services/environment'

SemverService = require '../services/semver'
config = require '../config'


# TODO separate bundle for app that doesn't require this
# firebase = require 'firebase/app'
# require 'firebase/messaging'

ONE_DAY_MS = 3600 * 24 * 1000

class PushService
  constructor: ->
    if window? and not Environment.isNativeApp('freeroam') and not Environment.isScreenshotter()
      @isReady = new Promise (@resolveReady) => null
      @isFirebaseImported = Promise.all [
        `import(/* webpackChunkName: "firebase" */'firebase/app')`
        `import(/* webpackChunkName: "firebase" */'firebase/messaging')`
      ]
      .then ([firebase, firebaseMessaging]) ->
        firebase.initializeApp {
          apiKey: config.FIREBASE.API_KEY
          authDomain: config.FIREBASE.AUTH_DOMAIN
          databaseURL: config.FIREBASE.DATABASE_URL
          projectId: config.FIREBASE.PROJECT_ID
          messagingSenderId: config.FIREBASE.MESSAGING_SENDER_ID
        }
        @firebaseMessaging = firebase.messaging()

  setFirebaseServiceWorker: (registration) =>
    if @isFirebaseImported
      @isFirebaseImported.then =>
        @resolveReady?()

  init: ({model}) ->
    onReply = (reply) ->
      payload = reply.additionalData.payload or reply.additionalData.data
      if payload.conversationId
        model.conversationMessage.create {
          body: reply.additionalData.inlineReply
          conversationId: payload.conversationId
        }
    model.portal.call 'push.registerAction', {
      action: 'reply'
    }, onReply

  register: ({model, isAlwaysCalled}) ->
    Promise.all [
      model.portal.call 'push.register'
      model.portal.call 'app.getDeviceId'
      .catch (err) -> ''
    ]
    .then ([{token, sourceType} = {}, deviceId]) ->
      if token?
        if not isAlwaysCalled or not model.cookie.get 'isPushTokenStored'
          appVersion = Environment.getAppVersion 'freeroam'
          isIosFCM = appVersion and SemverService.gte(appVersion, '1.3.1')
          sourceType ?= if Environment.isAndroid() \
                        then 'android'
                        else if isIosFCM
                        then 'ios-fcm'
                        else 'ios'
          language = model.l.getLanguageStr()
          model.pushToken.upsert {token, sourceType, language, deviceId}
          model.cookie.set 'isPushTokenStored', 1, {ttlMs: ONE_DAY_MS}

        model.pushToken.setCurrentPushToken token
    .catch (err) ->
      unless err.message is 'Method not found'
        console.log err

  registerWeb: =>
    if config.ENV is config.ENVS.DEV
      return Promise.resolve {
        token: navigator?.userAgent, sourceType: 'web-fcm'
      }

    @isReady.then ->
      @firebaseMessaging.requestPermission()
      .then =>
        @firebaseMessaging.getToken()
    .then (token) ->
      {token, sourceType: 'web-fcm'}

  # subscribeToTopic: ({model, topic, token}) =>
  #   if token
  #     tokenPromise = Promise.resolve token
  #   else
  #     tokenPromise = @firebaseMessaging.getToken()
  #
  #   tokenPromise
  #   .then (token) ->
  #     model.pushTopic.subscribe {topic, token}
  #   .catch (err) ->
  #     console.log 'caught', err


module.exports = new PushService()
