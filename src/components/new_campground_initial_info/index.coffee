z = require 'zorium'
RxBehaviorSubject = require('rxjs/BehaviorSubject').BehaviorSubject
_map = require 'lodash/map'

PrimaryInput = require '../primary_input'
PrimaryButton = require '../primary_button'
CoordinatePicker = require '../coordinate_picker'
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

    @$mapButton = new PrimaryButton()

  isCompleted: =>
    @fields.name.valueSubject.getValue() and
      @fields.location.valueSubject.getValue()

  getTitle: =>
    @model.l.get 'newCampgroundPage.title'

  render: =>
    z '.z-new-campground-initial-info',
      z '.g-grid',
        z 'label.field',
          z '.name', @model.l.get 'newCampgroundInitialInfo.campgroundName'
          z @$nameInput,
            hintText: @model.l.get 'newCampgroundInitialInfo.campgroundName'

        z 'label.field.where',
          z '.name', @model.l.get 'newCampgroundInitialInfo.where'
          z '.input',
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
