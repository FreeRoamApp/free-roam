module.exports = class Comment
  namespace: 'comments'
  constructor: ({@auth}) -> null

  create: ({body, topId, topType, parentId, parentType}) =>
    ga? 'send', 'event', 'social_interaction', 'comment', "#{parentId}"
    @auth.call "#{@namespace}.create", {
      body, topId, topType, parentId, parentType
    }, {invalidateAll: true}

  flag: (id) =>
    @auth.call "#{@namespace}.flag", {id}

  getAllByTopId: (topId, {sort, skip, limit, groupId} = {}) =>
    @auth.stream "#{@namespace}.getAllByTopId", {
      topId, sort, skip, limit, groupId
    }

  deleteByComment: (comment, {groupId}) =>
    @auth.call "#{@namespace}.deleteByComment", {
      comment, groupId
    }, {invalidateAll: true}

  deleteAllByGroupIdAndUserId: (groupId, userId, {topId} = {}) =>
    @auth.call "#{@namespace}.deleteAllByGroupIdAndUserId", {
      groupId, userId, topId
    }, {invalidateAll: true}
