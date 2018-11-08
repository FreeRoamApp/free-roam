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
UploadOverlay = require '../upload_overlay'
PrimaryButton = require '../primary_button'
SecondaryButton = require '../secondary_button'
FlatButton = require '../flat_button'
PrimaryInput = require '../primary_input'
colors = require '../../colors'
config = require '../../config'

if window?
  require './index.styl'

B_IN_MB = 1024 * 1024

module.exports = class EditProfile
  constructor: ({@model, @router, group}) ->
    me = @model.user.getMe()

    @$avatar = new Avatar()
    @$avatarButton = new PrimaryButton()
    @$uploadOverlay = new UploadOverlay {@model}

    @$saveButton = new PrimaryButton()
    @$recordButton = new SecondaryButton()
    @$cacheSizeButton = new FlatButton()
    @$clearCacheButton = new FlatButton()

    @usernameValueStreams = new RxReplaySubject 1
    @usernameValueStreams.next me.map (me) ->
      me.username or ''
    @usernameError = new RxBehaviorSubject null
    @$usernameInput = new PrimaryInput
      valueStreams: @usernameValueStreams
      error: @usernameError

    @newPasswordValue = new RxBehaviorSubject ''
    @newPasswordError = new RxBehaviorSubject null
    @$newPasswordInput = new PrimaryInput
      value: @newPasswordValue
      error: @newPasswordError

    @currentPasswordValue = new RxBehaviorSubject ''
    @currentPasswordError = new RxBehaviorSubject null
    @$currentPasswordInput = new PrimaryInput
      value: @currentPasswordValue
      error: @currentPasswordError


    @state = z.state
      me: me
      avatarImage: null
      avatarDataUrl: null
      avatarUploadError: null
      group: group
      username: @usernameValueStreams.switch()
      newPassword: @newPasswordValue
      currentPassword: @currentPasswordValue
      isSaving: false
      isSaved: false

  save: =>
    {avatarImage, username, newPassword, currentPassword,
      me, isSaving, group} = @state.getValue()
    if isSaving
      return

    @state.set isSaving: true, avatarUploadError: null
    @usernameError.next null
    @newPasswordError.next null
    @currentPasswordError.next null

    userDiff = {}

    if username and username isnt me?.username
      userDiff.username = username

    if newPassword
      userDiff.password = newPassword
      userDiff.currentPassword = currentPassword

    @model.user.upsert userDiff, {file: avatarImage}
    .then =>
      @state.set
        avatarImage: null
        avatarDataUrl: null
        isSaving: false
        isSaved: true

    .catch (err) =>
      error = try
        JSON.parse err.message
      catch
        {}
      @state.set
        isSaving: false
      if error.info?.field is 'password'
        @newPasswordError.next(
          @model.l.get(error.info?.langKey) or @model.l.get 'general.error'
        )
      else if error.info?.field is 'currentPassword'
        @currentPasswordError.next(
          @model.l.get(error.info?.langKey) or @model.l.get 'general.error'
        )
      else if error.info?.field is 'avatarImage'
        @state.set avatarUploadError:
          @model.l.get(error.info?.langKey) or @model.l.get 'general.error'
      else
        @usernameError.next(
          @model.l.get(error.info?.langKey) or @model.l.get 'general.error'
        )

  render: =>
    {me, avatarUploadError, avatarDataUrl, group, newPassword
      players, isSaving, isSaved} = @state.getValue()

    z '.z-edit-profile',
      z '.g-grid',

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

        if newPassword
          z '.section',
            z '.input',
              z @$currentPasswordInput,
                hintText: @model.l.get 'editProfile.currentPassword'
                isFullWidth: false
                type: 'password'

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

        if navigator?.serviceWorker
          z '.section',
            z '.title', @model.l.get 'editProfile.offlineMode'
            z '.description', @model.l.get 'editProfile.description'
            z '.actions',
              z @$recordButton,
                text: @model.l.get 'editProfile.startRecording'
                onclick: =>
                  @model.offlineData.record()
              z @$cacheSizeButton, {
                onclick: =>
                  @model.portal.call 'cache.getSizeByCacheName', {
                    cacheName: 'recorded'
                  }
                  .then (size) =>
                    size += localStorage?.offlineCache?.length or 0
                    mb = Math.round(100 * size / B_IN_MB) / 100
                    alert @model.l.get 'editProfile.sizeInfo', {
                      replacements:
                        size: "#{mb}mb"
                    }
                text: @model.l.get 'editProfile.checkCacheSize'
              }
              z @$clearCacheButton, {
                onclick: =>
                  @model.portal.call 'cache.clearByCacheName', {
                    cacheName: 'recorded'
                  }
                  delete localStorage.offlineCache
                text: @model.l.get 'editProfile.clearOfflineData'
              }

        z '.actions',
          z '.button',
            z @$saveButton,
              onclick: @save
              text: if isSaving \
                    then @model.l.get 'general.loading'
                    else if isSaved
                    then @model.l.get 'general.saved'
                    else @model.l.get 'general.save'
