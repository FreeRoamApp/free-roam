module.exports = class PushTopic
  namespace: 'pushTopics'

  constructor: ({@auth}) -> null

  subscribe: ({groupId, sourceType, sourceId}) =>
    @auth.call "#{@namespace}.subscribe", {
      groupId, sourceType, sourceId
    }

  unsubscribe: ({groupId, sourceType, sourceId}) =>
    @auth.call "#{@namespace}.unsubscribe", {
      groupId, sourceType, sourceId
    }, {invalidateAll: true}

  getAll: =>
    @auth.stream "#{@namespace}.getAll", {}
