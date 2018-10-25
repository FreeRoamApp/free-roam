z = require 'zorium'

AppBar = require '../../components/app_bar'
ButtonMenu = require '../../components/button_menu'
EditProfile = require '../../components/edit_profile'
config = require '../../config'

if window?
  require './index.styl'

module.exports = class EditProfilePage
  constructor: ({@model, requests, router, serverData, group}) ->
    @$appBar = new AppBar {@model}
    @$buttonMenu = new ButtonMenu {@model, router}
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
        $topLeftButton: z @$buttonMenu
        $topRightButton: z '.p-edit-profile_top-right', {
          onclick: (e) =>
            e?.preventDefault()
            @model.auth.logout()
            @router.go 'home'
        }, @model.l.get 'editProfile.logoutButtonText'
      }
      @$editProfile
