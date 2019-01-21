module.exports = class EarnAction
  namespace: 'earnActions'

  constructor: ({@auth}) -> null

  getAll: (groupId, {platform} = {}) =>
    @auth.stream "#{@namespace}.getAll", {groupId, platform}

  incrementByAction: (groupId, action, options = {}) =>
    {timestamp, successKey} = options
    @auth.call "#{@namespace}.incrementByAction", {
      groupId, action, timestamp, successKey
    }, {invalidateAll: true}
