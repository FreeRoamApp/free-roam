z = require 'zorium'

Icon = require '../icon'
PrimaryInput = require '../primary_input'
PrimaryTextarea = require '../primary_textarea'
colors = require '../../colors'
config = require '../../config'

if window?
  require './index.styl'

module.exports = class EditProfileAbout
  constructor: ({@model, @router, @fields}) ->
    me = @model.user.getMe()

    @$occupationIcon = new Icon()
    @$homeIcon = new Icon()
    @$startTimeIcon = new Icon()

    @$bioTextarea = new PrimaryTextarea
      valueStreams: @fields.bio.valueStreams

    @$occupationInput = new PrimaryInput
      valueStreams: @fields.occupation.valueStreams
      error: @fields.occupation.errorSubject

    @$homeInput = new PrimaryInput
      valueStreams: @fields.home.valueStreams
      error: @fields.home.errorSubject

    @$startTimeInput = new PrimaryInput
      valueStreams: @fields.startTime.valueStreams
      error: @fields.startTime.errorSubject

    @state = z.state
      me: me

  render: =>
    {me, isSaving, isSaved} = @state.getValue()

    z '.z-edit-profile-about',
      z '.g-grid',
        z '.section',
          z '.input',
            z @$bioTextarea,
              hintText: @model.l.get 'general.bio'
              isFullWidth: false

        z '.section',
          z '.icon',
            z @$occupationIcon,
              icon: 'work'
              isTouchTarget: false
              color: colors.$primary500
          z '.input',
            z @$occupationInput,
              hintText: @model.l.get 'editProfile.occupation'
              isFullWidth: false

        z '.section',
          z '.icon',
            z @$homeIcon,
              icon: 'home'
              isTouchTarget: false
              color: colors.$primary500
          z '.input',
            z @$homeInput,
              hintText: @model.l.get 'editProfile.home'
              isFullWidth: false

        z '.section',
          z '.icon',
            z @$startTimeIcon,
              icon: 'flag'
              isTouchTarget: false
              color: colors.$primary500
          z '.input',
            z @$startTimeInput,
              hintText: @model.l.get 'editProfile.startTime'
              isFullWidth: false
              type: 'date'
