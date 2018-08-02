_reduce = require 'lodash/reduce'
_defaultsDeep = require 'lodash/defaultsDeep'
_mapValues = require 'lodash/mapValues'
_keys = require 'lodash/keys'
_reduce = require 'lodash/reduce'
_findKey = require 'lodash/findKey'
_filter = require 'lodash/filter'
RxBehaviorSubject = require('rxjs/BehaviorSubject').BehaviorSubject

DateService = require '../services/date'
config = require '../config'

# missing: card_info, channel picker, edit group, edit group change badge
# events 'participants', 'begins', 'ends'
# group list 'members'
# thread points
# friendspage
# profile page share

class Language
  constructor: ({language, @cookie} = {}) ->
    language ?= 'en'

    @language = new RxBehaviorSubject language

    # also update gulpfile ContextReplacementPlugin for moment
    if window? and config.ENV is config.ENVS.PROD
      # done like this so compile time is quicker
      @files = window.languageStrings
    else
      files = {
        strings: null
        paths: null
      }

      @files = _mapValues files, (val, file) ->
        _reduce config.LANGUAGES, (obj, lang) ->
          obj[lang] = try require "../lang/#{lang}/#{file}_#{lang}.json" \
                      catch e then null
          obj
        , {}

    @setLanguage language

  getLanguageByCountry: (country) ->
    country = country?.toUpperCase()
    if country in [
      'AR', 'BO', 'CR', 'CU', 'DM', 'EC', 'SV', 'GQ', 'GT', 'HN', 'MX'
      'NI', 'PA', 'PE', 'ES', 'UY', 'VE'
    ]
      'es'
    else if country is 'IT'
      'it'
    else if country is 'BR'
      'pt'
    else if country is 'PL'
      'pl'
    else if country is 'FR'
      'fr'
    else
      'en'

  setLanguage: (language) =>
    @language.next language
    @cookie?.set 'language', language
    DateService.setL this
    DateService.setLocale language

  getLanguage: => @language

  getLanguageStr: => @language.getValue()

  getAll: ->
    config.LANGUAGES

  getAllUrlLanguages: ->
    ['en', 'es', 'pt']

  # some of this would probably make more sense in router...
  getNonGamePages: ->
    [
      'policies', 'privacy', 'termsOfService'
    ]

  getRouteKeyByValue: (routeValue) =>
    language = @getLanguageStr()
    _findKey(@files['paths'][language], (route) ->
      route is routeValue) or _findKey(@files['paths']['en'], (route) ->
        route is routeValue)

  getAllPathsByRouteKey: (routeKey) =>
    languages = @getAllUrlLanguages()
    _reduce languages, (paths, language) =>
      path = @files['paths'][language]?[routeKey]
      if path
        paths[language] = path
      paths
    , {}

  get: (strKey, {replacements, file, language} = {}) =>
    file ?= 'strings'
    language ?= @getLanguageStr()
    baseResponse = @files[file][language]?[strKey] or
                    @files[file]['en']?[strKey] or ''

    unless baseResponse
      console.log 'missing', file, strKey

    if typeof baseResponse is 'object'
      # some languages (czech) have many plural forms
      pluralityCount = replacements[baseResponse.pluralityCheck]
      baseResponse = baseResponse.plurality[pluralityCount] or
                      baseResponse.plurality.other or ''

    _reduce replacements, (str, replace, key) ->
      find = ///{#{key}}///g
      str.replace find, replace
    , baseResponse


module.exports = Language
