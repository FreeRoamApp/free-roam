z = require 'zorium'
colors = require '../../colors'
_isEmpty = require 'lodash/isEmpty'
_filter = require 'lodash/filter'

Icon = require '../icon'
Spinner = require '../spinner'
UserList = require '../user_list'

if window?
  require './index.styl'

module.exports = class Friends
  constructor: ({@model, selectedProfileDialogUser}) ->
    @$spinner = new Spinner()
    @$friendsIcon = new Icon()

    friends = @model.connection.getAllByType 'friend'
    requests = @model.connection.getAllByType 'friendRequest'

    # onlineUsers = friends.map (friends) ->
    #   _filter friends, 'isOnline'

    # @$onlineUsersList = new UserList {
    #   @model, friends: onlineUsers, selectedProfileDialogUser
    # }

    @$requestsList = new UserList {
      @model, selectedProfileDialogUser
      users: requests
    }

    @$friendsList = new UserList {
      @model, selectedProfileDialogUser
      users: friends
    }

    @state = z.state
      friends: friends
      requests: requests
      # onlineUsersCount: onlineUsers.map (friends) -> friends?.length
      friendsCount: friends.map (friends) -> friends?.length

  render: =>
    {friends, requests, onlineUsersCount, friendsCount} = @state.getValue()

    console.log 'friends', friends, requests

    z '.z-friends',
      if not _isEmpty requests
        z '.g-grid',
        @$requestsList
      if friends and _isEmpty friends
        z '.no-friends',
          z @$friendsIcon,
            icon: 'friends'
            size: '100px'
            color: colors.$black12
          @model.l.get 'friends.emptyState'
      else if friends
        z '.g-grid',
          # z 'h2.title',
          #   @model.l.get 'friends.friendsOnline'
          #   z 'span', innerHTML: ' &middot; '
          #   onlineUsersCount
          # @$onlineUsersList

          # z 'h2.title',
          #   @model.l.get 'friends.friendsAll'
          #   z 'span', innerHTML: ' &middot; '
          #   friendsCount
          @$friendsList
      else
        @$spinner
