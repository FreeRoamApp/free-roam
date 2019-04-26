z = require 'zorium'
_map = require 'lodash/map'

Avatar = require '../avatar'
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
              @selectedProfileDialogUser.next user.userInfo
        },
          z '.avatar',
            z user.$avatar,
              user: user.userInfo
              bgColor: colors.$grey200
          z '.right',
            z '.name', @model.user.getDisplayName user.userInfo
