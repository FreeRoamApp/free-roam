module.exports = class UserSettings
  namespace: 'userSettings'

  constructor: ({@auth}) -> null

  getByMe: =>
    @auth.stream "#{@namespace}.getByMe", {}

  upsert: (userSettings) =>
    @auth.call "#{@namespace}.upsert", userSettings, {invalidateAll: true}
