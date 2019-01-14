module.exports = class UserRig
  namespace: 'userRigs'

  constructor: ({@auth}) -> null

  getByMe: =>
    @auth.stream "#{@namespace}.getByMe", {}

  upsert: (userRig) =>
    @auth.call "#{@namespace}.upsert", userRig, {invalidateAll: true}
