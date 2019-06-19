z = require 'zorium'
RxObservable = require('rxjs/Observable').Observable
require 'rxjs/add/observable/combineLatest'
require 'rxjs/add/observable/of'

BasePage = require '../base'
# AppBar = require '../../components/app_bar'
# ButtonMenu = require '../../components/button_menu'
Profile = require '../../components/profile'
config = require '../../config'
colors = require '../../colors'

if window?
  require './index.styl'

module.exports = class ProfilePage extends BasePage
  @hasBottomBar: true

  constructor: ({@model, @router, requests, serverData, group, @$bottomBar}) ->
    user = @clearOnUnmount requests.switchMap ({route}) =>
      if route.params.username
        @model.user.getByUsername route.params.username, {embed: ['data']}
      else if route.params.id
        @model.user.getById route.params.id, {embed: ['data']}
      else
        @model.user.getMe {embed: ['data']}

    trip = user.switchMap (user) =>
      if user
        @model.trip.getByUserIdAndType user.id, 'past'
      else
        RxObservable.of null

    @userAndTrip = RxObservable.combineLatest(user, trip, (vals...) -> vals)

    # @$appBar = new AppBar {@model}
    # @$buttonMenu = new ButtonMenu {@model, @router}
    @$profile = new Profile {@model, @router, user, type: 'user'}

    @state = z.state
      me: @model.user.getMe()
      user: user

  getMeta: =>
    @userAndTrip.map ([user, trip]) =>
      cacheBust = new Date(trip?.lastUpdateTime).getTime()
      {
        title: @model.l.get 'profilePage.title', {
          replacements:
            name: @model.user.getDisplayName user
        }
        description: @model.l.get 'profilePage.description', {
          replacements:
            name: @model.user.getDisplayName user
        }
        openGraph:
          image: @model.image.getSrcByPrefix trip?.imagePrefix, {
            size: 'large', cacheBust
          }
      }

  render: =>
    {user, me} = @state.getValue()

    isMe = user and user?.id is me?.id

    z '.p-profile',
      # z @$appBar, {
      #   title: if user
      #     @model.l.get 'profilePage.title', {
      #       replacements:
      #         name: @model.user.getDisplayName user
      #     }
      #   style: 'primary'
      #   $topLeftButton: z @$buttonMenu, {color: colors.$header500Icon}
      # }

      # this is here so vdom doesn't change which div bototmBar is for
      # (other page components all have appBars)
      z '.app-bar-placeholder'

      @$profile
      if not user or isMe
        @$bottomBar
