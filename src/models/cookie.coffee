config = require '../config'

COOKIE_DURATION_MS = 365 * 24 * 3600 * 1000 # 1 year

class Cookie
  constructor: ({initialCookies, @setCookie, @host}) ->
    @cookies = initialCookies or {}

  getCookieOpts: (key, ttlMs) ->
    host = @host
    isSubdomain = host?.indexOf(config.HOST) isnt -1
    if not host or isSubdomain
      host = config.HOST
    ttlMs ?= COOKIE_DURATION_MS
    hostname = host.split(':')[0]

    {
      path: '/'
      expires: new Date(Date.now() + ttlMs)
      # Set cookie for subdomains
      domain: '.' + hostname
    }

  set: (key, value, {ttlMs} = {}) =>
    ttlMs ?= COOKIE_DURATION_MS
    @cookies[key] = value
    options = @getCookieOpts key, ttlMs
    @setCookie key, value, options

  get: (key) =>
    @cookies[key]

module.exports = Cookie
