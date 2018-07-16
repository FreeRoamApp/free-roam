Environment = require '../services/environment'

module.exports = class PushToken
  namespace: 'pushTokens'

  constructor: ({@auth, @pushToken}) -> null

  upsert: ({token, sourceType, language, deviceId} = {}) =>
    @auth.call "#{@namespace}.upsert", {token, sourceType, language, deviceId}

  setCurrentPushToken: (pushToken) =>
    @pushToken.next pushToken

  getCurrentPushToken: =>
    @pushToken
