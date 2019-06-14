z = require 'zorium'
_isEmpty = require 'lodash/isEmpty'
_map = require 'lodash/map'

Avatar = require '../avatar'
ProfileDialog = require '../profile_dialog'
Icon = require '../icon'
SecondaryButton = require '../secondary_button'
colors = require '../../colors'

if window?
  require './index.styl'

module.exports = class UserList
  constructor: (options) ->
    {@model, @router, users, actionButtons} = options

    @state = z.state
      users: users.map (users) ->
        _map users, (user) ->
          {
            $avatar: new Avatar()
            $karmaIcon: new Icon()
            actionButtons: _map actionButtons, (actionButton) ->
              {
                $button: new SecondaryButton()
                actionButton
              }
            userInfo: user
          }

  render: ({onclick} = {}) =>
    {users} = @state.getValue()

    z '.z-user-list',
      _map users, (user) =>
        z '.user', {
          onclick: =>
            if onclick
              onclick user.userInfo
            else
              if user.userInfo.username
                @router.go 'profile', {
                  username: user.userInfo.username
                }
              else
                @router.go 'profileById', {
                  id: user.userInfo.id
                }
              # @model.overlay.open new ProfileDialog {
              #   @model, @router, user: user.userInfo
              # }
        },
          z '.avatar',
            z user.$avatar,
              user: user.userInfo
              bgColor: colors.$grey200
              size: '52px'
          z '.info',
            z '.username', @model.user.getDisplayName user.userInfo
            if not _isEmpty user.actionButtons
              z '.actions',
                _map user.actionButtons, ({actionButton, $button}) ->
                  z '.action',
                    z $button,
                      isOutline: true
                      heightPx: 28
                      text: actionButton.text
                      onclick: (e) ->
                        e.stopPropagation()
                        actionButton.onclick user.userInfo
          if _isEmpty user.actionButtons
            z '.right',
                z '.icon',
                  z user.$karmaIcon,
                    icon: 'karma'
                    size: '18px'
                    isTouchTarget: false
                    color: colors.$secondary500
                user.userInfo.karma
