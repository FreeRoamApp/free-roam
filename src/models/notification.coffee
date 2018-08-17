config = require '../config'

module.exports = class Notification
  namespace: 'notifications'

  constructor: ({@auth}) -> null

  getAll: ({groupUuid}) =>
    @auth.stream "#{@namespace}.getAll", {groupUuid}
