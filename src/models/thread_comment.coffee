module.exports = class ThreadComment
  namespace: 'threadComments'
  constructor: ({@auth}) -> null

  create: ({body, threadUuid, parentUuid, parentType}) =>
    ga? 'send', 'event', 'social_interaction', 'thread_comment', "#{parentUuid}"
    @auth.call "#{@namespace}.create", {body, threadUuid, parentUuid, parentType}, {
      invalidateAll: true
    }

  flag: (uuid) =>
    @auth.call "#{@namespace}.flag", {uuid}

  getAllByThreadUuid: (threadUuid, {sort, skip, limit, groupUuid} = {}) =>
    @auth.stream "#{@namespace}.getAllByThreadUuid", {
      threadUuid, sort, skip, limit, groupUuid
    }

  deleteByThreadComment: (threadComment, {groupUuid}) =>
    @auth.call "#{@namespace}.deleteByThreadComment", {
      threadComment, groupUuid
    }, {invalidateAll: true}

  deleteAllByGroupUuidAndUserUuid: (groupUuid, userUuid, {threadUuid} = {}) =>
    @auth.call "#{@namespace}.deleteAllByGroupUuidAndUserUuid", {
      groupUuid, userUuid, threadUuid
    }, {invalidateAll: true}
