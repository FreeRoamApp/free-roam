_defaults = require 'lodash/defaults'

module.exports = class GroupRole
  namespace: 'groupRoles'

  constructor: ({@auth}) -> null

  createByGroupId: (groupId, diff) =>
    @auth.call "#{@namespace}.createByGroupId", _defaults({groupId}, diff), {
      invalidateAll: true
    }

  getAllByGroupId: (groupId) =>
    @auth.stream "#{@namespace}.getAllByGroupId", {groupId}

  deleteByGroupIdAndRoleId: (groupId, roleId) =>
    @auth.call "#{@namespace}.deleteByGroupIdAndRoleId", {groupId, roleId}, {
      invalidateAll: true
    }

  updatePermissions: (options) =>
    @auth.call "#{@namespace}.updatePermissions", options, {
      invalidateAll: true
    }
