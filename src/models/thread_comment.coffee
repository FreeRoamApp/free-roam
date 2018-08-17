module.exports = class ThreadComment
  namespace: 'threadComments'
  constructor: ({@auth}) -> null

  create: ({body, threadId, parentId, parentType}) =>
    ga? 'send', 'event', 'social_interaction', 'thread_comment', "#{parentId}"
    @auth.call "#{@namespace}.create", {body, threadId, parentId, parentType}, {
      invalidateAll: true
    }

  flag: (id) =>
    @auth.call "#{@namespace}.flag", {id}

  getAllByThreadId: (threadId, {sort, skip, limit, groupId} = {}) =>
    @auth.stream "#{@namespace}.getAllByThreadId", {
      threadId, sort, skip, limit, groupId
    }

  deleteByThreadComment: (threadComment, {groupId}) =>
    @auth.call "#{@namespace}.deleteByThreadComment", {
      threadComment, groupId
    }, {invalidateAll: true}

  deleteAllByGroupIdAndUserId: (groupId, userId, {threadId} = {}) =>
    @auth.call "#{@namespace}.deleteAllByGroupIdAndUserId", {
      groupId, userId, threadId
    }, {invalidateAll: true}
