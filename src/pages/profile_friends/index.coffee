z = require 'zorium'
RxBehaviorSubject = require('rxjs/BehaviorSubject').BehaviorSubject
_map = require 'lodash/map'

AppBar = require '../../components/app_bar'
ButtonBack = require '../../components/button_back'
UserList = require '../../components/user_list'
config = require '../../config'
colors = require '../../colors'

if window?
  require './index.styl'

module.exports = class ProfileFriendsPage
  hideDrawer: true

  constructor: ({@model, @router, requests, serverData, group}) ->
    @user = requests.switchMap ({route}) =>
      if route.params.username
        @model.user.getByUsername route.params.username
      else
        @model.user.getById route.params.id

    @$appBar = new AppBar {@model}
    @$buttonBack = new ButtonBack {@model, @router}
    friends = @user.switchMap (user) =>
      @model.connection.getAllByUserIdAndType user.id, 'friend'
      .map (connections) ->
        _map connections, (connection) -> connection?.other
    @$friendsList = new UserList {
      @model, @router, users: friends
    }

    @state = z.state
      user: @user

  getMeta: =>
    @user.map (user) =>
      {
        title: @model.l.get 'profileFriendsPage.title', {
          replacements:
            name: @model.user.getDisplayName user
        }
        description: @model.l.get 'profileFriendsPage.description', {
          replacements:
            name: @model.user.getDisplayName user
        }
      }

  render: =>
    {user} = @state.getValue()

    z '.p-profile-friends',
      z @$appBar, {
        title: if user
          @model.l.get 'profileFriendsPage.title', {
            replacements:
              name: @model.user.getDisplayName user
          }
        style: 'primary'
        $topLeftButton: z @$buttonBack, {color: colors.$header500Icon}
      }
      @$friendsList
