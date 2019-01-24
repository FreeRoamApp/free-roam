module.exports = class Ban
  namespace: 'bans'

  constructor: ({@auth}) -> null

  getAllByGroupId: (groupId, {duration} = {}) =>
    @auth.stream "#{@namespace}.getAllByGroupId", {duration, groupId}

  getByGroupIdAndUserId: (groupId, userId) =>
    @auth.stream "#{@namespace}.getByGroupIdAndUserId", {groupId, userId}

  banByGroupIdAndUserId: (groupId, userId, {duration, type} = {}) =>
    @auth.call "#{@namespace}.banByGroupIdAndUserId", {
      userId, groupId, duration, type
    }, {invalidateAll: true}

  unbanByGroupIdAndUserId: (groupId, userId) =>
    @auth.call "#{@namespace}.unbanByGroupIdAndUserId", {userId, groupId}, {
      invalidateAll: true
    }
