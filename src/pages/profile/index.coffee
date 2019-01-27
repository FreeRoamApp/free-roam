z = require 'zorium'

# AppBar = require '../../components/app_bar'
# ButtonMenu = require '../../components/button_menu'
Profile = require '../../components/profile'
config = require '../../config'
colors = require '../../colors'

if window?
  require './index.styl'

module.exports = class ProfilePage
  @hasBottomBar: true

  constructor: ({@model, @router, requests, serverData, group, @$bottomBar}) ->
    @user = requests.switchMap ({route}) =>
      if route.params.username
        @model.user.getByUsername route.params.username
      else
        @model.user.getMe()

    # @$appBar = new AppBar {@model}
    # @$buttonMenu = new ButtonMenu {@model, @router}
    @$profile = new Profile {@model, @router, @user, type: 'user'}

    @state = z.state
      user: @user

  getMeta: =>
    @user.map (user) =>
      {
        title: @model.l.get 'profilePage.title', {
          replacements:
            name: @model.user.getDisplayName user
        }
        description: @model.l.get 'profilePage.description', {
          replacements:
            name: @model.user.getDisplayName user
        }
      }

  render: =>
    {user} = @state.getValue()

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
      @$profile
      @$bottomBar
