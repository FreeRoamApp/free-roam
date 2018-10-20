z = require 'zorium'

EditProfile = require '../../components/edit_profile'
config = require '../../config'

module.exports = class EditProfilePage
  constructor: ({@model, requests, router, serverData, group}) ->
    @$editProfile = new EditProfile {@model, router, group}

  getMeta: =>
    {
      title: @model.l.get 'editProfilePage.title'
    }

  render: =>
    z '.p-edit-profile',
      @$editProfile
