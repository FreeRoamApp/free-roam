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

###
Location (use place_search), photos

Is this a campground?

Want to help us help others? Add a little more info about this campground so
others can find it

# TODO:
placeSearch with button on right to add, and some other way to get coordinate from map

after added, they can tap to edit / add photos
###

module.exports = class NewTripAddCheckIn
  constructor: ({@model, @router}) ->
    me = @model.user.getMe()

    @fields =
      location:
        valueSubject: new RxBehaviorSubject ''
        errorSubject: new RxBehaviorSubject null
      startDate:
        valueSubject: new RxBehaviorSubject []
        errorSubject: new RxBehaviorSubject null
      endDate:
        valueSubject: new RxBehaviorSubject []
        errorSubject: new RxBehaviorSubject null


    @$locationInput = new PrimaryInput
      value: @fields.location.valueSubject
      error: @fields.location.errorSubject

    @$startDateInput = new PrimaryInput
      value: @fields.startDate.valueSubject
      error: @fields.startDate.errorSubject

    @$mapButton = new PrimaryButton()
    @$addVideoButton = new PrimaryButton()

    @state = z.state {
    }

  render: =>
    {} = @state.getValue()

    z '.z-new-trip-add-check-in',
      z '.g-grid',
        'Ability to add photos and dates coming soon!'
        # z 'label.field.where',
        #   z '.name', @model.l.get 'newPlaceInitialInfo.where'
        #   z '.form',
        #     z '.input',
        #       z @$locationInput,
        #         hintText: @model.l.get 'newPlaceInitialInfo.coordinates'
        #     z '.button',
        #       z @$mapButton,
        #         text: @model.l.get 'newPlaceInitialInfo.coordinatesFromMap'
        #         isFullWidth: false
        #         onclick: =>
        #           @model.overlay.open new CoordinatePicker {
        #             @model, @router, coordinates: @fields.location.valueSubject
        #           }
