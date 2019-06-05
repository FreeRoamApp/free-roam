_includes = require 'lodash/includes'

config = require '../config'

class Environment
  isMobile: ({userAgent} = {}) ->
    userAgent ?= navigator?.userAgent
    ///
      Mobile
    | iP(hone|od|ad)
    | Android
    | BlackBerry
    | IEMobile
    | Kindle
    | NetFront
    | Silk-Accelerated
    | (hpw|web)OS
    | Fennec
    | Minimo
    | Opera\ M(obi|ini)
    | Blazer
    | Dolfin
    | Dolphin
    | Skyfire
    | Zune
    ///.test userAgent

  isFacebook: ->
    window? and window.name.indexOf('canvas_fb') isnt -1

  isTwitch: ->
    window?.Twitch

  isScreenshotter: ({userAgent} = {}) ->
    userAgent ?= navigator?.userAgent
    _includes userAgent, 'SCREENSHOTTER'

  isAndroid: ({userAgent} = {}) ->
    userAgent ?= navigator?.userAgent
    _includes userAgent, 'Android'

  isIos: ({userAgent} = {}) ->
    userAgent ?= navigator?.userAgent
    Boolean userAgent?.match /iP(hone|od|ad)/g

  isNativeApp: (gameKey, {userAgent} = {}) ->
    userAgent ?= navigator?.userAgent
    Boolean gameKey and
      _includes(userAgent?.toLowerCase(), " #{gameKey}/")

  isMainApp: (gameKey, {userAgent} = {}) ->
    userAgent ?= navigator?.userAgent
    Boolean gameKey and
      _includes(userAgent?.toLowerCase(), " #{gameKey}/#{gameKey}")

  isGroupApp: (groupAppKey, {userAgent} = {}) ->
    userAgent ?= navigator?.userAgent
    Boolean groupAppKey and
      _includes(userAgent?.toLowerCase(), " freeroam/#{groupAppKey}/")

  getAppKey: ({userAgent} = {}) ->
    userAgent ?= navigator?.userAgent
    matches = userAgent.match /freeroam\/([a-zA-Z0-9-]+)/
    matches?[1] or 'browser'

  getAppVersion: (gameKey, {userAgent} = {}) ->
    userAgent ?= navigator?.userAgent
    regex = new RegExp("(#{gameKey})\/(?:[a-zA-Z0-9]+/)?([0-9\.]+)")
    matches = userAgent.match(regex)
    matches?[2]

  getPlatform: ({gameKey, userAgent} = {}) =>
    gameKey ?= 'freeroam'
    userAgent ?= navigator?.userAgent

    isApp = @isNativeApp gameKey, {userAgent}

    if @isFacebook() then 'facebook'
    else if @isTwitch() then 'twitch'
    else if isApp and @isIos(gameKey, {userAgent}) then 'ios'
    else if isApp and @isAndroid({userAgent}) then 'android'
    else 'web'

module.exports = new Environment()
