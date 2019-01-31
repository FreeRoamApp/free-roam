module.exports = class Subscription
  namespace: 'subscriptions'

  constructor: ({@auth}) -> null

  subscribe: ({groupId, sourceType, sourceId, isTopic}) =>
    @auth.call "#{@namespace}.subscribe", {
      groupId, sourceType, sourceId, isTopic
    }

  unsubscribe: ({groupId, sourceType, sourceId, isTopic}) =>
    @auth.call "#{@namespace}.unsubscribe", {
      groupId, sourceType, sourceId, isTopic
    }, {invalidateAll: true}

  sync: ({groupId}) =>
    @auth.call "#{@namespace}.sync", {groupId}, {invalidateAll: true}

  getAllByGroupId: (groupId) =>
    @auth.stream "#{@namespace}.getAllByGroupId", {groupId}
