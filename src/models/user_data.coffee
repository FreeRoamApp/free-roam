module.exports = class UserData
  namespace: 'userData'

  constructor: ({@auth}) -> null

  getByMe: =>
    @auth.stream "#{@namespace}.getByMe", {}

  getByUserId: =>
    @auth.stream "#{@namespace}.getByUserId", {}

  upsert: (userData) =>
    @auth.call "#{@namespace}.upsert", userData, {invalidateAll: true}
