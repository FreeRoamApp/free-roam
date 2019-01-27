z = require 'zorium'

AppBar = require '../../components/app_bar'
ButtonBack = require '../../components/button_back'
ProfileAttachments = require '../../components/profile_attachments'
config = require '../../config'
colors = require '../../colors'

if window?
  require './index.styl'

module.exports = class ProfileAttachmentsPage
  hideDrawer: true

  constructor: ({@model, @router, requests, serverData, group}) ->
    @user = requests.switchMap ({route}) =>
      if route.params.username
        @model.user.getByUsername route.params.username
      else
        @model.user.getById route.params.id

    @$appBar = new AppBar {@model}
    @$buttonBack = new ButtonBack {@model, @router}
    @$profileAttachments = new ProfileAttachments {@model, @router, @user, type: 'user'}

    @state = z.state
      user: @user

  getMeta: =>
    @user.map (user) =>
      {
        title: @model.l.get 'profileAttachmentsPage.title', {
          replacements:
            name: @model.user.getDisplayName user
        }
        description: @model.l.get 'profileAttachmentsPage.description', {
          replacements:
            name: @model.user.getDisplayName user
        }
      }

  render: =>
    {user} = @state.getValue()

    z '.p-profile-attachments',
      z @$appBar, {
        title: if user
          @model.l.get 'profileAttachmentsPage.title', {
            replacements:
              name: @model.user.getDisplayName user
          }
        style: 'primary'
        $topLeftButton: z @$buttonBack, {color: colors.$header500Icon}
      }
      @$profileAttachments
