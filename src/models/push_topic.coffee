module.exports = class PushTopic
  namespace: 'pushTopics'

  constructor: ({@auth}) -> null

  subscribe: ({groupId, appId, sourceType, sourceId}) =>
    @auth.call "#{@namespace}.subscribe", {
      groupId, appId, sourceType, sourceId
    }
