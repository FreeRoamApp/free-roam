_mapValues = require 'lodash/mapValues'
_reduce = require 'lodash/reduce'
_uniq = require 'lodash/uniq'

config = require '../config'

files = {
  strings: null
  cards: null
  addons: null
  paths: null
  languages: null
  fortnite: null
}

module.exports = getJsonString: (language) ->
  files = _mapValues files, (val, file) ->
    if file is 'paths'
      languages = config.LANGUAGES
    else
      languages = _uniq([language, 'en'])

    # always need en for fallback
    _reduce languages, (obj, lang) ->
      obj[lang] = try require "./#{lang}/#{file}_#{lang}" \
                  catch e then null
      obj
    , {}
  str = JSON.stringify files
  "if(typeof window !== 'undefined'){window.languageStrings=#{str};} "
