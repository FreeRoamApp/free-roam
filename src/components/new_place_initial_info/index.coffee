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
CoordinatePickerOverlay = require '../coordinate_picker_overlay'
Icon = require '../icon'
MapService = require '../../services/map'
colors = require '../../colors'
config = require '../../config'

if window?
  require './index.styl'

module.exports = class NewPlaceInitialInfo
  constructor: ({@model, @router, @fields}) ->
    me = @model.user.getMe()

    @$nameInput = new PrimaryInput
      valueStreams: @fields.name.valueStreams
      error: @fields.name.errorSubject

    @$locationInput = new PrimaryInput
      valueStreams: @fields.location.valueStreams
      error: @fields.location.errorSubject

    @$detailsTextarea = new Textarea {
      defaultHeight: 100
      valueStreams: @fields.details.valueStreams
    }

    if @fields.subType
      @$subTypeDropdown = new Dropdown {
        valueStreams: @fields.subType.valueStreams
      }

    @$mapButton = new PrimaryButton()
    @$currentLocationButton = new SecondaryButton()

    @state = z.state {
      nameValue: @fields.name.valueStreams.switch()
      locationValue: @fields.location.valueStreams.switch()
    }

  isCompleted: =>
    {nameValue, locationValue} = @state.getValue()
    nameValue and locationValue

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
                  @model.overlay.open new CoordinatePickerOverlay {
                    @model, @router
                    onPick: (place) =>
                      lat = Math.round(10000 * place.location.lat) / 10000
                      lon = Math.round(10000 * place.location.lon) / 10000
                      @fields.location.valueStreams.next RxObservable.of(
                        "#{lat}, #{lon}"
                      )
                      Promise.resolve null
                  }

            if navigator?.geolocation
              z '.button',
                z @$currentLocationButton,
                  icon: 'crosshair'
                  isOutline: true
                  text: @model.l.get 'general.currentLocation'
                  onclick: =>
                    MapService.getLocation()
                    .then ({lat, lon}) =>
                      @fields.location.valueStreams.next RxObservable.of(
                        "#{lat}, #{lon}"
                      )

        z 'label.field.details',
          z '.name', @model.l.get 'newPlaceInitialInfo.details'
          z @$detailsTextarea,
            hintText: @model.l.get 'newPlaceInitialInfo.placeDetails'
