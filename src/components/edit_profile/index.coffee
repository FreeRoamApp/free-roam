z = require 'zorium'
RxReplaySubject = require('rxjs/ReplaySubject').ReplaySubject
RxBehaviorSubject = require('rxjs/BehaviorSubject').BehaviorSubject

Avatar = require '../avatar'
Icon = require '../icon'
EditProfileGeneral = require '../edit_profile_general'
UploadOverlay = require '../upload_overlay'
Tabs = require '../tabs'
Icon = require '../icon'
colors = require '../../colors'
config = require '../../config'

if window?
  require './index.styl'

B_IN_MB = 1024 * 1024

module.exports = class EditProfile
  constructor: ({@model, @router, group}) ->
    @me = @model.user.getMe()

    @$avatar = new Avatar()
    @$uploadOverlay = new UploadOverlay {@model}
    @avatarImage = new RxBehaviorSubject null
    rotationValueSubject = new RxBehaviorSubject null

    @fields =
      username:
        valueStreams: new RxReplaySubject 1
        errorSubject: new RxBehaviorSubject null
      name:
        valueStreams: new RxReplaySubject 1
        errorSubject: new RxBehaviorSubject null
      instagram:
        valueStreams: new RxReplaySubject 1
        errorSubject: new RxBehaviorSubject null
      web:
        valueStreams: new RxReplaySubject 1
        errorSubject: new RxBehaviorSubject null
      bio:
        valueStreams: new RxReplaySubject 1
        errorSubject: new RxBehaviorSubject null
      newPassword:
        valueSubject: new RxBehaviorSubject ''
        errorSubject: new RxBehaviorSubject null
      currentPassword:
        valueSubject: new RxBehaviorSubject ''
        errorSubject: new RxBehaviorSubject null

    @resetValueStreams()

    @$editProfileGeneral = new EditProfileGeneral {
      @model, @router, @fields
    }

    @$editIcon = new Icon()

    @$tabs = new Tabs {@model}

    @state = z.state
      me: @me
      avatarImage: @avatarImage.map (file) =>
        if file
          @model.image.parseExif(
            file, null, rotationValueSubject
          )
        file
      avatarRotation: rotationValueSubject
      avatarDataUrl: null
      avatarUploadError: null
      isSaving: false
      isSaved: false
      username: @fields.username.valueStreams.switch()
      name: @fields.name.valueStreams.switch()
      instagram: @fields.instagram.valueStreams.switch()
      web: @fields.web.valueStreams.switch()
      bio: @fields.bio.valueStreams.switch()
      newPassword: @fields.newPassword.valueSubject
      currentPassword: @fields.currentPassword.valueSubject

  resetValueStreams: =>
    @fields.username.valueStreams.next @me.map (me) ->
      me.username or ''

    @fields.name.valueStreams.next @me.map (me) ->
      me.name or ''

    @fields.instagram.valueStreams.next @me.map (me) ->
      me.links?.instagram or ''

    @fields.web.valueStreams.next @me.map (me) ->
      me.links?.web or ''

    @fields.bio.valueStreams.next @me.map (me) ->
      me.bio or ''

  save: =>
    {avatarImage, username, name, instagram, web, bio, newPassword,
      currentPassword, me, isSaving, group} = @state.getValue()

    if isSaving
      return

    @model.user.requestLoginIfGuest me
    .then =>
      @state.set isSaving: true, avatarUploadError: null
      @fields.username.errorSubject.next null
      @fields.newPassword.errorSubject.next null
      @fields.currentPassword.errorSubject.next null

      if instagram or web
        links = {instagram, web}
        userDiff = {links}
      else
        userDiff = {}

      if bio
        userDiff.bio = bio

      if username and username isnt me?.username
        userDiff.username = username

      if name and name isnt me?.name
        userDiff.name = name

      if newPassword
        userDiff.password = newPassword
        userDiff.currentPassword = currentPassword

      @model.user.upsert userDiff, {file: avatarImage}
      .then =>
        @avatarImage.next null
        @state.set
          avatarDataUrl: null
          isSaving: false
          isSaved: true

        @router.go 'profileMe'

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
    {me, avatarUploadError, avatarDataUrl, avatarRotation, group, newPassword
      players, isSaving, isSaved} = @state.getValue()

    z '.z-edit-profile',
      z '.top',
        if avatarUploadError
          avatarUploadError
        z '.avatar',
          z @$avatar, {
            src: avatarDataUrl, user: me, size: '90px'
            rotation: avatarRotation
          }
          z '.edit',
            z @$editIcon,
              icon: 'edit'
              isTouchTarget: false
              color: colors.$secondary500
              size: '18px'
          z '.upload-overlay',
            z @$uploadOverlay,
              onSelect: ({file, dataUrl}) =>
                @avatarImage.next file
                @state.set avatarDataUrl: dataUrl

      z @$tabs,
        isBarFixed: false
        tabs: [
          {
            $menuText: @model.l.get 'general.general'
            $el: @$editProfileGeneral
          }
          # {
          #   $menuText: @model.l.get 'general.about'
          #   $el: z @$usersNearby
          # }
          # {
          #   $menuText: @model.l.get 'general.settings'
          #   $el: z @$usersNearby
          # }
        ]
