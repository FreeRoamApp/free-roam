z = require 'zorium'
_map = require 'lodash/map'
require 'rxjs/add/operator/switchMap'

Avatar = require '../avatar'
DateService = require '../../services/date'
colors = require '../../colors'

if window?
  require './index.styl'

module.exports = class GroupAuditLog
  constructor: ({@model, @router, group}) ->

    @state = z.state {
      group
      logs: group.switchMap (group) =>
        @model.groupAuditLog.getAllByGroupId group.id
        .map (logs) ->
          _map logs, (log) ->
            {
              log: log
              $avatar: new Avatar()
            }
      me: @model.user.getMe()
    }

  render: =>
    {me, group, logs} = @state.getValue()

    z '.z-group-audit-log',
      z '.g-grid',
        z '.logs',
          _map logs, ({log, $avatar}) =>
            z '.log',
              z '.avatar',
                z $avatar, {user: log.user}
              z '.text',
                "#{@model.user.getDisplayName log.user} #{log.actionText}"
                z '.time',
                  DateService.fromNow log.time
