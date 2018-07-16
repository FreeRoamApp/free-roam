semverCompare = require 'semver-compare'
_padStart = require 'lodash/padStart'

ONE_MINUTE_S = 60
ONE_HOUR_S = 3600
ONE_DAY_S = 3600 * 24
ONE_WEEK_S = 3600 * 24 * 7

class DateService
  constructor: ->
    @setLocale 'en'

  setL: (@l) => null

  format: (date, format) ->
    # TODO: nothing uses this currently. don't use moment. could  use date-fns
    ''

  formatDuration: (duration) ->
    # https://stackoverflow.com/a/30134889
    match = duration.match(/PT(\d+H)?(\d+M)?(\d+S)?/)
    match = match.slice(1).map((x) ->
      return x?.replace(/\D/, '')
    )
    hours = _padStart parseInt(match[0]) or 0, 2, '0'
    minutes = _padStart parseInt(match[1]) or 0, 2, '0'
    seconds = _padStart parseInt(match[2]) or 0, 2, '0'
    if hours isnt '00'
      "#{hours}:#{minutes}:#{seconds}"
    else if minutes isnt '00'
      "#{minutes}:#{seconds}"
    else
      "00:#{seconds}"

  formatSeconds: (seconds) =>
    if seconds < ONE_MINUTE_S
      return parseInt(seconds) + @l.get 'time.secondShorthand'
    else if seconds < ONE_HOUR_S
      return parseInt(seconds / ONE_MINUTE_S) + @l.get 'time.minuteShorthand'
    else if seconds <= ONE_DAY_S
      return parseInt(seconds / ONE_HOUR_S) + @l.get 'time.hourShorthand'
    else if seconds <= ONE_WEEK_S
      return parseInt(seconds / ONE_DAY_S) + @l.get 'time.dayShorthand'

  fromNow: (date) =>
    unless date instanceof Date
      date = new Date date
    seconds = Math.abs (Date.now() - date.getTime()) / 1000
    if isNaN seconds
      '...'
    else if seconds < 30
      @l.get 'time.justNow'
    else if seconds < ONE_MINUTE_S
      return parseInt(seconds) + @l.get 'time.secondShorthand'
    else if seconds < ONE_HOUR_S
      return parseInt(seconds / ONE_MINUTE_S) + @l.get 'time.minuteShorthand'
    else if seconds <= ONE_DAY_S
      return parseInt(seconds / ONE_HOUR_S) + @l.get 'time.hourShorthand'
    else if seconds <= ONE_WEEK_S
      return parseInt(seconds / ONE_DAY_S) + @l.get 'time.dayShorthand'
    else
      return parseInt(seconds / ONE_WEEK_S) + @l.get 'time.weekShorthand'

  setLocale: (locale) ->
    null
    # @localeFile = if window?
    #   window?.dateLocales?[locale]
    # else
    #   require("date-fns/locale/#{locale}")


module.exports = new DateService()
