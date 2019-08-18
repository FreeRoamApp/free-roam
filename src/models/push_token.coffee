module.exports = class PushToken
  namespace: 'pushTokens'

  constructor: ({@auth, @pushToken}) -> null

  upsert: ({token, sourceType, deviceId} = {}) =>
    @auth.call "#{@namespace}.upsert", {token, sourceType, deviceId}

  setCurrentPushToken: (pushToken) =>
    @pushToken.next pushToken

  getCurrentPushToken: =>
    @pushToken
