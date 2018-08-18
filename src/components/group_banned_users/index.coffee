z = require 'zorium'
colors = require '../../colors'
_map = require 'lodash/map'
_startCase = require 'lodash/startCase'
log = require 'loga'

config = require '../../config'
Icon = require '../icon'
Avatar = require '../avatar'

if window?
  require './index.styl'

module.exports = class GroupBannedUsers
  constructor: ({@model, @portal, bans, @selectedProfileDialogUser}) ->
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
              @selectedProfileDialogUser.next banInfo.user
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
