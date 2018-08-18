module.exports = class UserBlock
  namespace: 'userBlocks'

  constructor: ({@auth}) -> null

  getAll: =>
    @auth.stream "#{@namespace}.getAll", {}

  getAllIds: =>
    @auth.stream "#{@namespace}.getAllIds", {}

  blockByUserId: (userId) =>
    @auth.call "#{@namespace}.blockByUserId", {userId}, {invalidateAll: true}

  unblockByUserId: (userId) =>
    @auth.call "#{@namespace}.unblockByUserId", {userId}, {invalidateAll: true}

  isBlocked: (blockedIds, userId) ->
    blockedIds and blockedIds.indexOf(userId) isnt -1
