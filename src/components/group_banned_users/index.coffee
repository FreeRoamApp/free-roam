z = require 'zorium'
colors = require '../../colors'
_map = require 'lodash/map'
_startCase = require 'lodash/startCase'

config = require '../../config'
Icon = require '../icon'
Avatar = require '../avatar'
ProfileDialog = require '../profile_dialog'

if window?
  require './index.styl'

module.exports = class GroupBannedUsers
  constructor: ({@model, @router, bans}) ->
    @state = z.state
      bans: bans.map (bans) ->
        _map bans, (ban) ->
          {
            $avatar: new Avatar()
            banInfo: ban
          }

  render: =>
    {bans} = @state.getValue()

    z '.z-group-banned-users',
      z '.g-grid',
        _map bans, ({$avatar, banInfo}) =>
          z '.user', {
            onclick: =>
              @model.overlay.open new ProfileDialog {
                @model, @router
                user: banInfo.user
              }
          },
            z '.avatar',
              z $avatar,
                user: banInfo.user
                bgColor: colors.$grey200
            z '.right',
              z '.name', banInfo.user.username
              z '.banned-by',
                @model.l.get 'groupBannedUsers.bannedBy'
                ': ' + banInfo.bannedByUser.username
