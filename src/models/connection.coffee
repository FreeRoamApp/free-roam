module.exports = class Connection
  namespace: 'connections'

  constructor: ({@auth}) -> null

  getAllIdsByType: (type) =>
    @auth.stream "#{@namespace}.getAllIdsByType", {type}

  getAllByType: (type) =>
    @auth.stream "#{@namespace}.getAllByType", {type}

  getAllByUserIdAndType: (userId, type) =>
    @auth.stream "#{@namespace}.getAllByUserIdAndType", {userId, type}

  getAllGrouped: (type) =>
    @auth.stream "#{@namespace}.getAllGrouped", {type}

  upsertByUserIdAndType: (userId, type) =>
    @auth.call "#{@namespace}.upsertByUserIdAndType", {userId, type}, {
      invalidateAll: true
    }

  acceptRequestByUserIdAndType: (userId, type) =>
    @auth.call "#{@namespace}.acceptRequestByUserIdAndType", {userId, type}, {
      invalidateAll: true
    }

  deleteByUserIdAndType: (userId, type) =>
    @auth.call "#{@namespace}.deleteByUserIdAndType", {userId, type}, {
      invalidateAll: true
    }

  isConnectedByUserIdAndType: (userId, type) =>
    @getAllGrouped()
    .map (groupedIds) ->
      groupedIds?[type] and groupedIds[type].indexOf(userId) isnt -1
