module.exports = class Conversation
  namespace: 'conversations'

  constructor: ({@auth}) -> null

  create: ({userIds, name, description, groupId}) =>
    @auth.call "#{@namespace}.create", {userIds, name, description, groupId}, {
      invalidateAll: true
    }

  updateById: (id, options) =>
    {name, description, groupId} = options
    @auth.call "#{@namespace}.updateById", {
      id, name, description, groupId
    }, {invalidateAll: true}

  markReadByIdAndGroupId: (id, groupId) =>
    @auth.call "#{@namespace}.markReadById", {id, groupId}, {
      invalidateSingle:
        body:
          groupId: groupId
        path: "#{@namespace}.getAllByGroupId"
  }

  getAll: =>
    @auth.stream "#{@namespace}.getAll", {}

  getAllByGroupId: (groupId) =>
    @auth.stream "#{@namespace}.getAllByGroupId", {groupId}

  getById: (id) =>
    @auth.stream "#{@namespace}.getById", {id}
