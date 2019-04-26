module.exports = class Connection
  namespace: 'connections'

  constructor: ({@auth}) -> null

  getAllIdsByType: (type) =>
    @auth.stream "#{@namespace}.getAllIdsByType", {type}

  getAllByType: (type) =>
    @auth.stream "#{@namespace}.getAllByType", {type}

  upsertByUserIdAndType: (userId, type) =>
    @auth.call "#{@namespace}.upsertByUserIdAndType", {userId, type}, {
      invalidateAll: true
    }

  deleteByUserIdAndType: (userId, type) =>
    @auth.call "#{@namespace}.deleteByUserIdAndType", {userId, type}, {
      invalidateAll: true
    }
