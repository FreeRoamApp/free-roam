_pick = require 'lodash/pick'
RxObservable = require('rxjs/Observable').Observable
require 'rxjs/add/observable/defer'
require 'rxjs/add/operator/toPromise'
require 'rxjs/add/observable/fromPromise'
require 'rxjs/add/operator/switchMap'
require 'rxjs/add/operator/take'
require 'rxjs/add/operator/publishReplay'

Environment = require '../services/environment'
config = require '../config'

module.exports = class Auth
  constructor: (options) ->
    {@exoid, @pushToken, @l, @cookie, @userAgent, @portal} = options

    @waitValidAuthCookie = RxObservable.defer =>
      accessToken = @cookie.get config.AUTH_COOKIE
      language = @l.getLanguageStr()
      (if accessToken
        @exoid.getCached 'users.getMe'
        .then (user) =>
          if user?
            return {accessToken}
          @exoid.call 'users.getMe'
          .then ->
            return {accessToken}
        .catch =>
          @exoid.call 'auth.login', {language}
      else
        @exoid.call 'auth.login', {language})
      .then ({accessToken}) =>
        @setAccessToken accessToken
    .publishReplay(1).refCount()

  setAccessToken: (accessToken) =>
    @cookie.set config.AUTH_COOKIE, accessToken

  logout: =>
    @setAccessToken ''
    language = @l.getLanguageStr()
    @exoid.call 'auth.login', {language}
    .then ({accessToken}) =>
      @setAccessToken accessToken
      @exoid.invalidateAll()

  join: ({email, username, password} = {}) =>
    @exoid.call 'auth.join', {email, username, password}
    .then ({username, accessToken}) =>
      @setAccessToken accessToken
      @exoid.invalidateAll()

  resetPassword: ({email, username} = {}) =>
    @exoid.call 'auth.resetPassword', {email, username}

  afterLogin: ({accessToken}) =>
    @setAccessToken accessToken
    @exoid.invalidateAll()
    pushToken = @pushToken.getValue()
    if pushToken
      pushToken ?= 'none'
      @portal.call 'app.getDeviceId'
      .catch -> null
      .then (deviceId) =>
        sourceType = if Environment.isAndroid() \
                     then 'android'
                     else 'ios-fcm'
        @call 'pushTokens.upsert', {token: pushToken, sourceType, deviceId}
      .catch -> null

  login: ({username, password} = {}) =>
    @exoid.call 'auth.loginUsername', {username, password}
    .then @afterLogin

  loginLink: ({userId, token} = {}) =>
    @exoid.call 'auth.loginLink', {userId, token}
    .then @afterLogin

  stream: (path, body, options = {}) =>
    options = _pick options, [
      'isErrorable', 'clientChangesStream', 'ignoreCache', 'initialSortFn'
      'isStreamed', 'limit'
    ]
    @waitValidAuthCookie
    .switchMap =>
      @exoid.stream path, body, options

  call: (path, body, options = {}) =>
    {invalidateAll, invalidateSingle, additionalDataStream} = options

    @waitValidAuthCookie.take(1).toPromise()
    .then =>
      @exoid.call path, body, {additionalDataStream}
    .then (response) =>
      if invalidateAll
        console.log 'Invalidating all'
        @exoid.invalidateAll()
      else if invalidateSingle
        console.log 'Invalidating single', invalidateSingle
        @exoid.invalidate invalidateSingle.path, invalidateSingle.body
      response
