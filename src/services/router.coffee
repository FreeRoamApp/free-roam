qs = require 'qs'
_forEach = require 'lodash/forEach'
_isEmpty = require 'lodash/isEmpty'
_defaults = require 'lodash/defaults'
_forEach = require 'lodash/forEach'
_reduce = require 'lodash/reduce'
_kebabCase = require 'lodash/kebabCase'
RxObservable = require('rxjs/Observable').Observable
Environment = require '../services/environment'

SemverService = require '../services/semver'
ThemeService = require '../services/theme'
colors = require '../colors'
config = require '../config'

ev = (fn) ->
  # coffeelint: disable=missing_fat_arrows
  (e) ->
    $$el = this
    fn(e, $$el)
  # coffeelint: enable=missing_fat_arrows
isSimpleClick = (e) ->
  not (e.which > 1 or e.shiftKey or e.altKey or e.metaKey or e.ctrlKey)

class RouterService
  constructor: ({@router, @model, @host}) ->
    @history = if window? then [window.location.pathname] else []
    @requests = null
    @onBackFn = null

  goPath: (path, {ignoreHistory, reset, keepPreserved} = {}) =>
    unless keepPreserved
      @preservedRequest = null
    unless ignoreHistory
      @history.push(path or window?.location.pathname)

    if @history[0] is '/' or @history[0] is @get('home') or reset
      @history = [path]

    if path
      # store current page for app re-launch
      if Environment.isNativeApp('freeroam') and @model.cookie
        @model.cookie.set 'routerLastPath', path

      @router.go path

  go: (routeKey, replacements, options = {}) =>
    path = @get routeKey, replacements
    if options.qs
      @goPath "#{path}?#{qs.stringify options.qs}", options
    else
      @goPath path, options

  get: (routeKey, replacements, {language} = {}) =>
    route = @model.l.get routeKey, {file: 'paths', language}
    _forEach replacements, (value, key) ->
      route = route.replace ":#{key}", value
    route

  goOverlay: (routeKey, replacements, options = {}) =>
    @requests.take(1).subscribe (request) =>
      @preservedRequest = request
      @go routeKey, replacements, _defaults({keepPreserved: true}, options)

  setRequests: (@requests) => null

  openLink: (url) =>
    isAbsoluteUrl = url?.match /^(?:[a-z-]+:)?\/\//i
    freeRoamRegex = new RegExp "https?://(.*?)\.?(#{config.HOST})", 'i'
    isFreeRoam = url?.match freeRoamRegex
    if not isAbsoluteUrl or isFreeRoam
      path = if isFreeRoam \
             then url.replace freeRoamRegex, ''
             else url
      @goPath path
    else
      console.log 'open', url
      @model.portal.call 'browser.openWindow', {
        url: url
        target: '_system'
      }

  back: ({fromNative, fallbackPath} = {}) =>
    @preservedRequest = null
    if @onBackFn
      fn = @onBackFn()
      @onBack null
      return fn
    if @model.drawer.isOpen().getValue()
      return @model.drawer.close()
    if @history.length is 1 and fromNative and (
      @history[0] is '/' or @history[0] is @get 'home'
    )
      @model.portal.call 'app.exit'
    else if @history.length > 1 and window.history.length > 0
      window.history.back()
      @history.pop()
    else if fallbackPath
      @goPath fallbackPath, {reset: true}
    else
      @goPath '/'

  onBack: (@onBackFn) => null

  openInAppBrowser: (addon, {replacements} = {}) =>
    if _isEmpty(addon.data?.translatedLanguages) or
          addon.data?.translatedLanguages.indexOf(
            @model.l.getLanguageStr()
          ) isnt -1
      language = @model.l.getLanguageStr()
    else
      language = 'en'

    replacements ?= {}
    replacements = _defaults replacements, {lang: language}
    vars = addon.url.match /\{[a-zA-Z0-9]+\}/g
    url = _reduce vars, (str, variable) ->
      key = variable.replace /\{|\}/g, ''
      str.replace variable, replacements[key] or ''
    , addon.url
    @model.portal.call 'browser.openWindow', {
      url: url
      target: '_blank'
      options:
        statusbar: {
          color: ThemeService.getVariableValue colors.$primary700
        }
        toolbar: {
          height: 56
          color: ThemeService.getVariableValue colors.$tertiary700
        }
        title: {
          color: ThemeService.getVariableValue colors.$tertiary700Text
          staticText: @model.l.get "#{addon.key}.title", {
            file: 'addons'
          }
        }
        closeButton: {
          # https://jgilfelt.github.io/AndroidAssetStudio/icons-launcher.html#foreground.type=clipart&foreground.space.trim=1&foreground.space.pad=0.5&foreground.clipart=res%2Fclipart%2Ficons%2Fnavigation_close.svg&foreColor=fff%2C0&crop=0&backgroundShape=none&backColor=fff%2C100&effects=none&elevate=0
          image: 'close'
          # imagePressed: 'close_grey'
          align: 'left'
          event: 'closePressed'
        }
    }, (data) =>
      @model.portal.portal.onMessageInAppBrowserWindow data

  openAddon: (addon, {replacements} = {}) =>
    isNative = Environment.isNativeApp 'freeroam'
    appVersion = isNative and Environment.getAppVersion(
      'freeroam'
    )
    isNewIAB = isNative and SemverService.gte appVersion, '1.4.0'
    isExternalAddon = addon.url.substr(0, 4) is 'http'
    shouldUseIAB = isNative and isNewIAB and isExternalAddon

    if shouldUseIAB or addon.data?.isUnframeable
      @openInAppBrowser addon, {replacements}
    else
      @go 'toolByKey', {
        key: _kebabCase(addon.key)
      }, {
        query:
          replacements: JSON.stringify replacements
      }

  getStream: =>
    @router.getStream()

  getSubdomain: =>
    hostParts = @host.split '.'
    isStaging = hostParts[0] is 'free-roam-staging'
    isDevSubdomain = config.ENV is config.ENVS.DEV and hostParts.length is 7
    if (hostParts.length is 3 or isDevSubdomain) and not isStaging
      return hostParts[0]

  link: (node) =>
    node.properties.onclick = ev (e, $$el) =>
      if isSimpleClick e
        e.preventDefault()
        @openLink $$el.href

    return node


module.exports = RouterService
