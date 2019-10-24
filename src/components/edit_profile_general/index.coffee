z = require 'zorium'

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
  constructor: ({@model, @router, @fields, passwordReset}) ->
    me = @model.user.getMe()

    @$logoutButton = new FlatButton()

    @$rigInfo = new RigInfo {@model, @router}

    @$webIcon = new Icon()
    @$instagramIcon = new Icon()
    @$youtubeIcon = new Icon()
    @$facebookIcon = new Icon()

    @$usernameInput = new PrimaryInput
      valueStreams: @fields.username.valueStreams
      error: @fields.username.errorSubject

    @$emailInput = new PrimaryInput
      valueStreams: @fields.email.valueStreams
      error: @fields.email.errorSubject

    @$nameInput = new PrimaryInput
      valueStreams: @fields.name.valueStreams
      error: @fields.name.errorSubject

    @$instagramInput = new PrimaryInput
      valueStreams: @fields.instagram.valueStreams

    @$youtubeInput = new PrimaryInput
      valueStreams: @fields.youtube.valueStreams

    @$webInput = new PrimaryInput
      valueStreams: @fields.web.valueStreams

    @$facebookInput = new PrimaryInput
      valueStreams: @fields.facebook.valueStreams

    @$newPasswordInput = new PrimaryInput
      value: @fields.newPassword.valueSubject
      error: @fields.newPassword.errorSubject

    @$currentPasswordInput = new PrimaryInput
      value: @fields.currentPassword.valueSubject
      error: @fields.currentPassword.errorSubject

    @state = z.state
      me: me
      newPassword: @fields.newPassword.valueSubject
      passwordReset: passwordReset
      isEmailVerificationSent: false

  render: =>
    {me, newPassword, passwordReset, isSaving, isSaved,
      isEmailVerificationSent} = @state.getValue()

    z '.z-edit-profile-general',
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
            z @$emailInput,
              hintText: @model.l.get 'general.email'
              isFullWidth: false
            if isEmailVerificationSent
              z '.warning',
                @model.l.get 'editProfile.verifyEmailSent'
            else if me?.email and not me?.flags?.isEmailVerified
              z '.warning', {
                onclick: =>
                  @state.set isEmailVerificationSent: true
                  @model.user.resendVerficationEmail()
              },
                @model.l.get 'editProfile.verifyEmail'

        z '.section',
          z '.input',
            z @$newPasswordInput,
              hintText: @model.l.get 'editProfile.newPassword'
              isFullWidth: false
              type: 'password'
              disableAutoComplete: true

        if newPassword and not passwordReset
          z '.section',
            z '.input',
              z @$currentPasswordInput,
                hintText: @model.l.get 'editProfile.currentPassword'
                isFullWidth: false
                type: 'password'

        z @$rigInfo

        z '.title', @model.l.get 'editProfile.socialMedia'
        z '.section',
          z '.icon',
            z @$instagramIcon,
              icon: 'instagram'
              isTouchTarget: false
              color: colors.$primaryMain
          z '.input',
            z @$instagramInput,
              hintText: @model.l.get 'general.instagram'
              isFullWidth: false

        z '.section',
          z '.icon',
            z @$youtubeIcon,
              icon: 'youtube'
              isTouchTarget: false
              color: colors.$primaryMain
          z '.input',
            z @$youtubeInput,
              hintText: @model.l.get 'general.youtube'
              isFullWidth: false

        z '.section',
          z '.icon',
            z @$webIcon,
              icon: 'web'
              isTouchTarget: false
              color: colors.$primaryMain
          z '.input',
            z @$webInput,
              hintText: @model.l.get 'general.web'
              isFullWidth: false

        z '.section',
          z '.icon',
            z @$facebookIcon,
              icon: 'facebook'
              isTouchTarget: false
              color: colors.$primaryMain
          z '.input',
            z @$facebookInput,
              hintText: @model.l.get 'general.facebook'
              isFullWidth: false

        z '.actions',
          z '.button',
            z @$logoutButton,
              onclick: =>
                if confirm @model.l.get 'editProfile.logoutConfirm'
                  @model.auth.logout()
                  @router.go 'home'
              text: @model.l.get 'editProfile.logoutButtonText'
