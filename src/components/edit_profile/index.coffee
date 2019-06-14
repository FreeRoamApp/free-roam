z = require 'zorium'
RxReplaySubject = require('rxjs/ReplaySubject').ReplaySubject
RxBehaviorSubject = require('rxjs/BehaviorSubject').BehaviorSubject

Avatar = require '../avatar'
Icon = require '../icon'
EditProfileGeneral = require '../edit_profile_general'
EditProfileAbout = require '../edit_profile_about'
UploadOverlay = require '../upload_overlay'
Tabs = require '../tabs'
Icon = require '../icon'
DateService = require '../../services/date'
colors = require '../../colors'
config = require '../../config'

if window?
  require './index.styl'

B_IN_MB = 1024 * 1024

module.exports = class EditProfile
  constructor: ({@model, @router, group}) ->
    @me = @model.user.getMe()
    @meData = @model.userData.getByMe()

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
      facebook:
        valueStreams: new RxReplaySubject 1
        errorSubject: new RxBehaviorSubject null
      youtube:
        valueStreams: new RxReplaySubject 1
        errorSubject: new RxBehaviorSubject null

      bio:
        valueStreams: new RxReplaySubject 1
        errorSubject: new RxBehaviorSubject null
      occupation:
        valueStreams: new RxReplaySubject 1
        errorSubject: new RxBehaviorSubject null
      home:
        valueStreams: new RxReplaySubject 1
        errorSubject: new RxBehaviorSubject null
      startTime:
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
    @$editProfileAbout = new EditProfileAbout {
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
      youtube: @fields.youtube.valueStreams.switch()
      facebook: @fields.facebook.valueStreams.switch()

      bio: @fields.bio.valueStreams.switch()
      occupation: @fields.occupation.valueStreams.switch()
      home: @fields.home.valueStreams.switch()
      startTime: @fields.startTime.valueStreams.switch()

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

    @fields.youtube.valueStreams.next @me.map (me) ->
      me.links?.youtube or ''

    @fields.facebook.valueStreams.next @me.map (me) ->
      me.links?.facebook or ''

    @fields.bio.valueStreams.next @meData.map (meData) ->
      meData?.bio or ''

    @fields.occupation.valueStreams.next @meData.map (meData) ->
      meData?.occupation or ''

    @fields.home.valueStreams.next @meData.map (meData) ->
      meData?.home or ''

    @fields.startTime.valueStreams.next @meData.map (meData) ->
      if meData?.startTime
        DateService.format new Date(meData?.startTime), 'yyyy-mm-dd'
      else
        ''

  save: =>
    {avatarImage, username, name, instagram, web, youtube, facebook
       newPassword, currentPassword, me, isSaving, group
      bio, occupation, home, startTime} = @state.getValue()

    if isSaving
      return

    @model.user.requestLoginIfGuest me
    .then =>
      @state.set isSaving: true, avatarUploadError: null
      @fields.username.errorSubject.next null
      @fields.newPassword.errorSubject.next null
      @fields.currentPassword.errorSubject.next null

      if instagram or web or youtube or facebook
        links = {instagram, web, youtube, facebook}
        userDiff = {links}
      else
        userDiff = {}

      if username and username isnt me?.username
        userDiff.username = username

      if name and name isnt me?.name
        userDiff.name = name

      if newPassword
        userDiff.password = newPassword
        userDiff.currentPassword = currentPassword

      if startTime
        startTime = DateService.getLocalDateFromStr startTime

      Promise.all [
        @model.user.upsert userDiff, {file: avatarImage}
        @model.userData.upsert {bio, occupation, home, startTime}
      ]
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
          @fields.newPassword.errorSubject.next(
            @model.l.get(error.info?.langKey) or @model.l.get 'general.error'
          )
        else if error.info?.field is 'currentPassword'
          @fields.currentPassword.errorSubject.next(
            @model.l.get(error.info?.langKey) or @model.l.get 'general.error'
          )
        else if error.info?.field is 'avatarImage'
          @state.set avatarUploadError:
            @model.l.get(error.info?.langKey) or @model.l.get 'general.error'
        else
          @fields.username.errorSubject.next(
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
          {
            $menuText: @model.l.get 'general.about'
            $el: z @$editProfileAbout
          }
          # {
          #   $menuText: @model.l.get 'general.settings'
          #   $el: z @$usersNearby
          # }
        ]
