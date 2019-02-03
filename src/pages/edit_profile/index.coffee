z = require 'zorium'

AppBar = require '../../components/app_bar'
ButtonBack = require '../../components/button_back'
EditProfile = require '../../components/edit_profile'
config = require '../../config'

if window?
  require './index.styl'

module.exports = class EditProfilePage
  constructor: ({@model, requests, router, serverData, group}) ->
    @$appBar = new AppBar {@model}
    @$buttonBack = new ButtonBack {@model, router}
    @$editProfile = new EditProfile {@model, router, group}

  getMeta: =>
    {
      title: @model.l.get 'editProfilePage.title'
    }

  render: =>
    z '.p-edit-profile',
      z @$appBar, {
        title: @model.l.get 'editProfilePage.title'
        style: 'primary'
        $topLeftButton: z @$buttonBack
        $topRightButton: z '.p-edit-profile_top-right', {
          onclick: (e) =>
            e?.preventDefault()
            @model.auth.logout()
            @router.go 'home'
        }, @model.l.get 'editProfile.logoutButtonText'
      }
      @$editProfile
