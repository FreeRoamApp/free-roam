z = require 'zorium'
colors = require '../../colors'
_isEmpty = require 'lodash/isEmpty'
_map = require 'lodash/map'
_filter = require 'lodash/filter'

Icon = require '../icon'
Spinner = require '../spinner'
UserList = require '../user_list'

if window?
  require './index.styl'

module.exports = class Friends
  constructor: ({@model, @router}) ->
    @$spinner = new Spinner()
    @$friendsIcon = new Icon()

    friends = @model.connection.getAllByType 'friend'
    .map (connections) ->
      _map connections, (connection) -> connection?.other
    requests = @model.connection.getAllByType 'friendRequestReceived'
    .map (connections) ->
      _map connections, (connection) -> connection?.other

    # onlineUsers = friends.map (friends) ->
    #   _filter friends, 'isOnline'

    # @$onlineUsersList = new UserList {
    #   @model, @router, friends: onlineUsers
    # }

    @$requestsList = new UserList {
      @model, @router
      users: requests
      actionButtons: [
        {
          text: @model.l.get 'friends.accept'
          onclick: (user) =>
            @model.connection.acceptRequestByUserIdAndType(
              user.id, 'friend'
            )
        }
        {
          text: @model.l.get 'friends.decline'
          onclick: (user) =>
            @model.connection.deleteByUserIdAndType(
              user.id, 'friendRequestReceived'
            )
        }
      ]
    }

    @$friendsList = new UserList {
      @model, @router, users: friends
    }

    @state = z.state
      friends: friends
      requests: requests
      # onlineUsersCount: onlineUsers.map (friends) -> friends?.length
      friendsCount: friends.map (friends) -> friends?.length

  render: =>
    {friends, requests, onlineUsersCount, friendsCount} = @state.getValue()

    z '.z-friends',
      if not _isEmpty requests
        z '.g-grid',
          z '.title', @model.l.get 'friends.requests'
          z @$requestsList
      if friends and _isEmpty friends
        z '.empty',
          z '.image'
          z '.title', @model.l.get 'friends.emptyTitle'
          z '.description', @model.l.get 'friends.emptyDescription'
      else if friends
        z '.g-grid',
          # z 'h2.title',
          #   @model.l.get 'friends.friendsOnline'
          #   z 'span', innerHTML: ' &middot; '
          #   onlineUsersCount
          # @$onlineUsersList

          z '.title',
            @model.l.get 'friends.myFriends'
          #   z 'span', innerHTML: ' &middot; '
          #   friendsCount
          @$friendsList
      else
        @$spinner
