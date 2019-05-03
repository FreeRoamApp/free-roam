z = require 'zorium'

AppBar = require '../../components/app_bar'
ButtonBack = require '../../components/button_back'
EditProfile = require '../../components/edit_profile'
config = require '../../config'
colors = require '../../colors'

if window?
  require './index.styl'

module.exports = class EditProfilePage
  hideDrawer: true

  constructor: ({@model, requests, router, serverData, group}) ->
    @$appBar = new AppBar {@model}
    @$buttonBack = new ButtonBack {@model, router}
    @$editProfile = new EditProfile {@model, router, group}

    @state = z.state {
      isSaving: false
    }

  getMeta: =>
    {
      title: @model.l.get 'editProfilePage.title'
    }

  render: =>
    {isSaving} = @state.getValue()

    z '.p-edit-profile',
      z @$appBar, {
        title: @model.l.get 'editProfilePage.title'
        isPrimary: true
        $topLeftButton: z @$buttonBack, {color: colors.$primary500Text}
        $topRightButton: z '.p-edit-profile_top-right', {
          onclick: =>
            @state.set isSaving: true
            @$editProfile.save()
            .then =>
              @state.set isSaving: false
        },
          if isSaving
          then @model.l.get 'general.loading'
          else @model.l.get 'general.save'
      }
      @$editProfile
