z = require 'zorium'
RxBehaviorSubject = require('rxjs/BehaviorSubject').BehaviorSubject
_map = require 'lodash/map'
_uniq = require 'lodash/uniq'

PrimaryInput = require '../primary_input'
PrimaryButton = require '../primary_button'
CoordinatePicker = require '../coordinate_picker'
Icon = require '../icon'
colors = require '../../colors'
config = require '../../config'

if window?
  require './index.styl'

module.exports = class NewCampgroundInitialInfo
  constructor: ({@model, @router, @fields, @overlay$}) ->
    me = @model.user.getMe()

    @$nameInput = new PrimaryInput
      value: @fields.name.valueSubject
      error: @fields.name.errorSubject

    @$locationInput = new PrimaryInput
      value: @fields.location.valueSubject
      error: @fields.location.errorSubject

    @videoValue = new RxBehaviorSubject ''
    @videoError = new RxBehaviorSubject null
    @$videoInput = new PrimaryInput
      value: @videoValue
      error: @videoError

    @$mapButton = new PrimaryButton()
    @$addVideoButton = new PrimaryButton()

    @state = z.state {
      videos: @fields.videos.valueSubject.map (videos) ->
        _map videos, (video) ->
          {video, $removeIcon: new Icon()}
    }

  isCompleted: =>
    @fields.name.valueSubject.getValue() and
      @fields.location.valueSubject.getValue()

  getTitle: =>
    @model.l.get 'newCampgroundPage.title'

  render: =>
    {videos} = @state.getValue()

    z '.z-new-campground-initial-info',
      z '.g-grid',
        z 'label.field',
          z '.name', @model.l.get 'newCampgroundInitialInfo.campgroundName'
          z @$nameInput,
            hintText: @model.l.get 'newCampgroundInitialInfo.campgroundName'

        z 'label.field.where',
          z '.name', @model.l.get 'newCampgroundInitialInfo.where'
          z '.form',
            z '.input',
              z @$locationInput,
                hintText: @model.l.get 'newCampgroundInitialInfo.coordinates'
            z '.button',
              z @$mapButton,
                text: @model.l.get 'newCampgroundInitialInfo.coordinatesFromMap'
                isFullWidth: false
                onclick: =>
                  @overlay$.next new CoordinatePicker {
                    @model, @router, @overlay$
                    coordinates: @fields.location.valueSubject
                  }

        z 'label.field',
          z '.name', @model.l.get 'newCampgroundInitialInfo.video'
          z '.form',
            z '.input',
              z @$videoInput,
                hintText: @model.l.get 'newCampgroundInitialInfo.videoHint'
            z '.button',
              z @$addVideoButton,
                text: @model.l.get 'general.add'
                isFullWidth: false
                onclick: =>
                  oldVideos = _map videos, 'video'
                  @fields.videos.valueSubject.next _uniq oldVideos.concat [
                    @videoValue.getValue()
                  ]
                  @videoValue.next ''
          z '.videos',
            _map videos, ({video, $removeIcon}) =>
              z '.video',
                z '.url', video
                z '.remove',
                  z $removeIcon,
                    icon: 'close'
                    isTouchTarget: false
                    color: colors.$bgText500
                    onclick: =>
                      oldVideos = _map videos, 'video'
                      index = oldVideos.indexOf(video)
                      oldVideos.splice index, 1
                      @fields.videos.valueSubject.next oldVideos
