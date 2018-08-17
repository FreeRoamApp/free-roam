module.exports = class Conversation
  namespace: 'conversations'

  constructor: ({@auth}) -> null

  create: ({userUuids, name, description, groupUuid}) =>
    @auth.call "#{@namespace}.create", {userUuids, name, description, groupUuid}, {
      invalidateAll: true
    }

  updateByUuid: (id, options) =>
    {name, description, isSlowMode, slowModeCooldown, groupUuid} = options
    @auth.call "#{@namespace}.updateByUuid", {
      id, name, description, isSlowMode, slowModeCooldown, groupUuid
    }, {invalidateAll: true}

  markReadByUuidAndGroupUuid: (uuid, groupUuid) =>
    @auth.call "#{@namespace}.markReadByUuid", {uuid, groupUuid}, {
      invalidateSingle:
        body:
          groupUuid: groupUuid
        path: "#{@namespace}.getAllByGroupUuid"
  }

  getAll: =>
    @auth.stream "#{@namespace}.getAll", {}

  getAllByGroupUuid: (groupUuid) =>
    @auth.stream "#{@namespace}.getAllByGroupUuid", {groupUuid}

  getByUuid: (uuid) =>
    @auth.stream "#{@namespace}.getByUuid", {uuid}
