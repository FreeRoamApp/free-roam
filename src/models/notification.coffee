config = require '../config'

module.exports = class Notification
  namespace: 'notifications'

  constructor: ({@auth}) -> null

  getAll: ({groupId}) =>
    @auth.stream "#{@namespace}.getAll", {groupId}
