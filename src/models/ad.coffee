Environment = require '../services/environment'

config = require '../config'

module.exports = class Ad
  constructor: ({@cookie, @portal, @userAgent}) -> null

  hideAds: (timeMs) =>
    # not super secure, but works for now
    @cookie.set 'hideAdsUntil', Date.now() + timeMs
    @portal.call 'admob.hideBanner'

  isVisible: ({isWebOnly} = {}) =>
    hideAdsUntil = @cookie.get 'hideAdsUntil'
    isNativeApp = Environment.isNativeApp('freeroam', {@userAgent})
    isNinja = window?.location.href.indexOf('ninja') isnt -1
    isVisible = not hideAdsUntil or Date.now() > parseInt(hideAdsUntil)

    (not isWebOnly or not isNativeApp) and isVisible and not isNinja
