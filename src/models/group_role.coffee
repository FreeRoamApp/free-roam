_every = require 'lodash/every'
_find = require 'lodash/find'
_defaults = require 'lodash/defaults'

config = require '../config'

module.exports = class GroupRole
  namespace: 'groupRoles'

  constructor: ({@auth}) -> null

  createByGroupUuid: (groupUuid, diff) =>
    @auth.call "#{@namespace}.createByGroupUuid", _defaults({groupUuid}, diff), {
      invalidateAll: true
    }

  getAllByGroupUuid: (groupUuid) =>
    @auth.stream "#{@namespace}.getAllByGroupUuid", {groupUuid}

  deleteByGroupUuidAndRoleId: (groupUuid, roleUuid) =>
    @auth.call "#{@namespace}.deleteByGroupUuidAndRoleId", {groupUuid, roleUuid}, {
      invalidateAll: true
    }

  updatePermissions: (options) =>
    @auth.call "#{@namespace}.updatePermissions", options, {
      invalidateAll: true
    }
