z = require 'zorium'
Environment = require '../../services/environment'
RxReplaySubject = require('rxjs/BehaviorSubject').BehaviorSubject
RxBehaviorSubject = require('rxjs/BehaviorSubject').BehaviorSubject
require 'rxjs/add/operator/map'
require 'rxjs/add/operator/switchMap'
_map = require 'lodash/map'

Icon = require '../icon'
FlatButton = require '../flat_button'
PrimaryInput = require '../primary_input'
PrimaryTextarea = require '../primary_textarea'
RigInfo = require '../rig_info'
colors = require '../../colors'
config = require '../../config'

if window?
  require './index.styl'

module.exports = class EditProfileGeneral
  constructor: ({@model, @router, @fields}) ->
    me = @model.user.getMe()

    @$logoutButton = new FlatButton()

    @$rigInfo = new RigInfo {@model, @router}

    @$usernameInput = new PrimaryInput
      valueStreams: @fields.username.valueStreams
      error: @fields.username.errorSubject

    @$nameInput = new PrimaryInput
      valueStreams: @fields.name.valueStreams
      error: @fields.name.errorSubject

    @$instagramInput = new PrimaryInput
      valueStreams: @fields.instagram.valueStreams

    @$webInput = new PrimaryInput
      valueStreams: @fields.web.valueStreams

    @$bioTextarea = new PrimaryTextarea
      valueStreams: @fields.bio.valueStreams

    @$newPasswordInput = new PrimaryInput
      value: @fields.newPassword.value
      error: @fields.newPassword.errorSubject

    @$currentPasswordInput = new PrimaryInput
      value: @fields.currentPassword.value
      error: @fields.currentPassword.errorSubject

    @state = z.state
      me: me
      newPassword: @fields.newPassword.value

  render: =>
    {me, newPassword, players, isSaving, isSaved} = @state.getValue()

    z '.z-edit-profile',
      z '.g-grid',

        z '.section',
          z '.input',
            z @$nameInput,
              hintText: @model.l.get 'general.name'
              isFullWidth: false

        z '.section',
          z '.input',
            z @$usernameInput,
              hintText: @model.l.get 'general.username'
              isFullWidth: false

        z '.section',
          z '.input',
            z @$newPasswordInput,
              hintText: @model.l.get 'editProfile.newPassword'
              isFullWidth: false
              type: 'password'
              disableAutoComplete: true

        z @$rigInfo

        if newPassword
          z '.section',
            z '.input',
              z @$currentPasswordInput,
                hintText: @model.l.get 'editProfile.currentPassword'
                isFullWidth: false
                type: 'password'

        z '.section',
          z '.input',
            z @$instagramInput,
              hintText: @model.l.get 'general.instagram'
              isFullWidth: false

        z '.section',
          z '.input',
            z @$webInput,
              hintText: @model.l.get 'general.web'
              isFullWidth: false

        z '.section',
          z '.input',
            z @$bioTextarea,
              hintText: @model.l.get 'general.bio'
              isFullWidth: false

        z '.actions',
          z '.button',
            z @$logoutButton,
              onclick: =>
                if confirm @model.l.get 'editProfile.logoutConfirm'
                  @model.auth.logout()
                  @router.go 'home'
              text: @model.l.get 'editProfile.logoutButtonText'
