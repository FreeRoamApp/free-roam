module.exports = class Notification
  namespace: 'notifications'

  constructor: ({@auth}) -> null

  ICON_MAP:
    social: 'friends'
    privateMessage: 'chat'
    channelMessage: 'chat'
    channelMention: 'chat'

  getAll: =>
    @auth.stream "#{@namespace}.getAll", {}

  getUnreadCount: =>
    @auth.stream "#{@namespace}.getUnreadCount", {}
