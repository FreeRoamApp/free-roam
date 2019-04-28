z = require 'zorium'
_map = require 'lodash/map'

Avatar = require '../avatar'
Icon = require '../icon'
SecondaryButton = require '../secondary_button'
colors = require '../../colors'

if window?
  require './index.styl'

module.exports = class UserList
  constructor: ({@model, users, @selectedProfileDialogUser}) ->
    @state = z.state
      users: users.map (users) ->
        _map users, (user) ->
          {
            $avatar: new Avatar()
            $karmaIcon: new Icon()
            $actionButton: new SecondaryButton()
            userInfo: user
          }

  render: ({onclick, actionButton} = {}) =>
    {users} = @state.getValue()

    z '.z-user-list',
      _map users, (user) =>
        z '.user', {
          onclick: =>
            if onclick
              onclick user.userInfo
            else
              @selectedProfileDialogUser.next user.userInfo
        },
          z '.avatar',
            z user.$avatar,
              user: user.userInfo
              bgColor: colors.$grey200
              size: '52px'
          z '.info',
            z '.name', @model.user.getDisplayName user.userInfo
          z '.right',
            if actionButton
              z user.$actionButton,
                isOutline: true
                heightPx: 28
                text: actionButton.text
                onclick: (e) ->
                  e.stopPropagation()
                  actionButton.onclick user.userInfo
            else
              [
                z '.icon',
                  z user.$karmaIcon,
                    icon: 'karma'
                    size: '18px'
                    isTouchTarget: false
                    color: colors.$secondary500
                user.userInfo.karma
              ]
