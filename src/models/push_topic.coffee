module.exports = class PushTopic
  namespace: 'pushTopics'

  constructor: ({@auth}) -> null

  subscribe: ({groupUuid, appId, sourceType, sourceId}) =>
    @auth.call "#{@namespace}.subscribe", {
      groupUuid, appId, sourceType, sourceId
    }
