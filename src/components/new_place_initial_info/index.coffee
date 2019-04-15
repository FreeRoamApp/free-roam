z = require 'zorium'
RxBehaviorSubject = require('rxjs/BehaviorSubject').BehaviorSubject
RxObservable = require('rxjs/Observable').Observable
require 'rxjs/add/observable/of'
_map = require 'lodash/map'
_uniq = require 'lodash/uniq'

PrimaryInput = require '../primary_input'
PrimaryButton = require '../primary_button'
SecondaryButton = require '../secondary_button'
Dropdown = require '../dropdown'
Textarea = require '../textarea'
CoordinatePicker = require '../coordinate_picker'
Icon = require '../icon'
colors = require '../../colors'
config = require '../../config'

if window?
  require './index.styl'

module.exports = class NewPlaceInitialInfo
  constructor: ({@model, @router, @fields}) ->
    me = @model.user.getMe()

    @$nameInput = new PrimaryInput
      value: @fields.name.valueSubject
      error: @fields.name.errorSubject

    @$locationInput = new PrimaryInput
      valueStreams: @fields.location.valueStreams
      error: @fields.location.errorSubject

    @$detailsTextarea = new Textarea {
      defaultHeight: 100
      value: @fields.details.valueSubject
    }

    if @fields.subType
      @$subTypeDropdown = new Dropdown {value: @fields.subType.valueSubject}

    @$mapButton = new PrimaryButton()
    @$currentLocationButton = new SecondaryButton()

    @state = z.state {
      locationValue: @fields.location.valueStreams.switch()
    }

  isCompleted: =>
    {locationValue} = @state.getValue()
    @fields.name.valueSubject.getValue() and locationValue

  getTitle: =>
    @model.l.get 'newPlacePage.title', {
      replacements: {@prettyType}
    }

  render: =>
    z '.z-new-place-initial-info',
      z '.g-grid',
        z 'label.field',
          z '.name', @model.l.get 'newPlaceInitialInfo.placeName', {
            replacements: {@prettyType}
          }
          z @$nameInput,
            hintText: @prettyType

        if @fields.subType
          z 'label.field',
            z '.name', @model.l.get 'newPlaceInitialInfo.placeType'
            z @$subTypeDropdown,
              options: _map @subTypes, (text, key) ->
                {
                  value: key
                  text: text
                }

        z 'label.field.where',
          z '.name', @model.l.get 'newPlaceInitialInfo.where'
          z '.form',
            z '.input',
              z @$locationInput,
                hintText: @model.l.get 'newPlaceInitialInfo.coordinates', {
                  replacements: {@prettyType}
                }

            z '.or', @model.l.get 'general.or'

            z '.button',
              z @$mapButton,
                icon: 'map'
                text: @model.l.get 'newPlaceInitialInfo.coordinatesFromMap'
                onclick: =>
                  @model.overlay.open new CoordinatePicker {
                    @model, @router
                    coordinatesSteams: @fields.location.valueStreams
                  }

            if navigator?.geolocation
              z '.button',
                z @$currentLocationButton,
                  icon: 'crosshair'
                  isOutline: true
                  text: @model.l.get 'general.currentLocation'
                  onclick: =>
                    navigator.geolocation.getCurrentPosition (pos) =>
                      @fields.location.valueStreams.next RxObservable.of(
                        "#{pos.coords.latitude}, #{pos.coords.longitude}"
                      )

        z 'label.field.details',
          z '.name', @model.l.get 'newPlaceInitialInfo.details'
          z @$detailsTextarea,
            hintText: @model.l.get 'newPlaceInitialInfo.placeDetails'
