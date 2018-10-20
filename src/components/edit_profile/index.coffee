z = require 'zorium'
Environment = require '../../services/environment'
RxReplaySubject = require('rxjs/BehaviorSubject').BehaviorSubject
RxBehaviorSubject = require('rxjs/BehaviorSubject').BehaviorSubject
require 'rxjs/add/operator/map'
require 'rxjs/add/operator/switchMap'
_map = require 'lodash/map'
_startCase = require 'lodash/startCase'
_find = require 'lodash/find'

Avatar = require '../avatar'
Icon = require '../icon'
ActionBar = require '../action_bar'
UploadOverlay = require '../upload_overlay'
PrimaryButton = require '../primary_button'
SecondaryButton = require '../secondary_button'
PrimaryInput = require '../primary_input'
colors = require '../../colors'
config = require '../../config'

if window?
  require './index.styl'

module.exports = class EditProfile
  constructor: ({@model, @router, group}) ->
    me = @model.user.getMe()

    @usernameValueStreams = new RxReplaySubject 1
    @usernameValueStreams.next me.map (me) ->
      me.username or ''
    @usernameError = new RxBehaviorSubject null

    @$actionBar = new ActionBar {@model}

    @$avatar = new Avatar()
    @$avatarButton = new PrimaryButton()
    @$uploadOverlay = new UploadOverlay {@model}

    @$logoutButton = new SecondaryButton()

    @$usernameInput = new PrimaryInput
      valueStreams: @usernameValueStreams
      error: @usernameError


    @state = z.state
      me: me
      avatarImage: null
      avatarDataUrl: null
      avatarUploadError: null
      group: group
      username: @usernameValueStreams.switch()
      isSaving: false

  save: =>
    {avatarImage, username, me, isSaving, group} = @state.getValue()
    if isSaving
      return

    @state.set isSaving: true
    @usernameError.next null

    (if username and username isnt me?.username
      @model.user.setUsername username
      .catch (err) =>
        @usernameError.next JSON.stringify err
    else
      Promise.resolve null)
    .then =>
      if avatarImage
        @upload avatarImage
    .then =>
      @state.set isSaving: false
      @model.group.goPath group, 'groupProfile', {@router}

  upload: (file) =>
    @model.user.setAvatarImage file
    .then (response) =>
      @state.set
        avatarImage: null
        avatarDataUrl: null
        avatarUploadError: null
    .catch (err) =>
      @state.set avatarUploadError: err?.detail or JSON.stringify err

  render: =>
    {me, avatarUploadError, avatarDataUrl, group
      players, isSaving} = @state.getValue()

    z '.z-edit-profile',
      z @$actionBar, {
        isSaving
        cancel:
          onclick: =>
            @router.back()
        save:
          onclick: @save
      }

      # z '.section',
      #   z '.input',
      #     z @$usernameInput,
      #       hintText: @model.l.get 'general.username'

      z '.section',
        z '.title', @model.l.get 'editProfile.changeAvatar'
        if avatarUploadError
          avatarUploadError
        z '.flex',
          z '.avatar',
            z @$avatar, {src: avatarDataUrl, user: me, size: '64px'}
          z '.button',
            z @$avatarButton,
              text: @model.l.get 'editProfile.avatarButtonText'
              isFullWidth: false
              onclick: null
            z '.upload-overlay',
              z @$uploadOverlay,
                onSelect: ({file, dataUrl}) =>
                  @state.set avatarImage: file, avatarDataUrl: dataUrl

      z '.section',

        z @$logoutButton,
          text: @model.l.get 'editProfile.logoutButtonText'
          onclick: =>
            @model.auth.logout()
            @router.go 'home'
