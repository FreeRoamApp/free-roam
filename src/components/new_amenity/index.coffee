z = require 'zorium'
RxReplaySubject = require('rxjs/ReplaySubject').ReplaySubject
RxBehaviorSubject = require('rxjs/BehaviorSubject').BehaviorSubject
RxObservable = require('rxjs/Observable').Observable
require 'rxjs/add/observable/of'
_filter = require 'lodash/filter'
_reduce = require 'lodash/reduce'
_map = require 'lodash/map'

ActionBar = require '../action_bar'
PrimaryInput = require '../primary_input'
PrimaryButton = require '../primary_button'
SecondaryButton = require '../secondary_button'
Checkbox = require '../checkbox'
CoordinatePickerOverlay = require '../coordinate_picker_overlay'
ChangePlaceTypeDialog = require '../change_place_type_dialog'
DuplicatePlaceDialog = require '../duplicate_place_dialog'
Icon = require '../icon'
colors = require '../../colors'
config = require '../../config'

if window?
  require './index.styl'

# TODO: revamp this whole thing for editing
module.exports = class NewAmenity
  constructor: ({@model, @router, center, location, place}) ->
    me = @model.user.getMe()

    @$actionBar = new ActionBar {@model}

    @nameValue = new RxBehaviorSubject ''
    @nameError = new RxBehaviorSubject null
    @$nameInput = new PrimaryInput
      value: @nameValue
      error: @nameError

    @locationValueStreams = new RxReplaySubject 1
    @locationValueStreams.next location or RxObservable.of ''
    @locationError = new RxBehaviorSubject null
    @$locationInput = new PrimaryInput
      valueStreams: @locationValueStreams
      error: @locationError

    @$mapButton = new PrimaryButton()
    @$duplicateButton = new SecondaryButton()
    @$changeTypeButton = new SecondaryButton()

    amenities = [
      {amenity: 'dump', hasPrice: true}
      {amenity: 'water', hasPrice: true}
      {amenity: 'npwater', hasPrice: true}
      {amenity: 'groceries'}
      {amenity: 'propane'}
      {amenity: 'trash'}
      {amenity: 'recycle'}
      {amenity: 'shower'}
      {amenity: 'gas'}
      {amenity: 'laundry'}
    ]

    @amenities = _map amenities, ({amenity, hasPrice}) ->
      valueSubject = new RxBehaviorSubject false
      priceValueSubject = new RxBehaviorSubject ''
      {
        amenity
        hasPrice
        valueSubject
        priceValueSubject
        $priceInput: new PrimaryInput {value: priceValueSubject}
        $checkbox: new Checkbox {value: valueSubject}
      }

    @state = z.state {
      me: @model.user.getMe()
      isLoading: false
      center: center
      place: place
      locationValue: @locationValueStreams.switch()
    }

  upsert: (e) =>
    {isLoading, locationValue} = @state.getValue()
    unless isLoading
      @state.set isLoading: true

      amenities = _filter _map @amenities, ({amenity, valueSubject}) ->
        if valueSubject.getValue()
          amenity
        else
          null

      prices = _reduce @amenities, (obj, {amenity, priceValueSubject}) ->
        price = parseInt priceValueSubject.getValue()
        if price? and not isNaN price
          obj[amenity] = price
        obj
      , {}

      @model.amenity.upsert {
        name: @nameValue.getValue()
        location: locationValue
        amenities: amenities
        prices: prices
      }
      .then (amenity) =>
        @state.set isLoading: false

        # FIXME FIXME: rm HACK. for some reason thread is empty initially?
        # still unsure why
        setTimeout =>
          @router.go 'amenity', {
            slug: amenity.slug
          }
        , 200
      .catch =>
        @state.set isLoading: false

  render: =>
    {me, isLoading, center, place} = @state.getValue()

    console.log 'place', place

    z '.z-new-amenity',
      if place and me?.username in ['austin', 'roadpickle', 'big_boxtruck', 'vanwldr']
        z '.actions',
          z @$duplicateButton,
            text: @model.l.get 'editPlace.markAsDupe'
            isOutline: true
            onclick: =>
              @model.overlay.open new DuplicatePlaceDialog {
                @model, @router, place
              }
          z @$changeTypeButton,
            text: @model.l.get 'editPlace.changeType'
            isOutline: true
            onclick: =>
              @model.overlay.open new ChangePlaceTypeDialog {
                @model, @router, place
              }
      else if not place
        [
          z @$actionBar, {
            isSaving: isLoading
            cancel:
              text: @model.l.get 'general.discard'
              onclick: =>
                @router.back()
            save:
              text: @model.l.get 'general.done'
              onclick: @upsert
          }
          z '.g-grid',
            z 'label.field',
              z '.name', @model.l.get 'newAmenity.name'
              z @$nameInput,
                hintText: @model.l.get 'newAmenity.name'

            z 'label.field.where',
              z '.name', @model.l.get 'newPlaceInitialInfo.where'
              z @$locationInput,
                hintText: @model.l.get 'newPlaceInitialInfo.coordinates', {
                  replacements:
                    prettyType: 'Amenity'
                }

            z '.or', @model.l.get 'general.or'

            z '.button',
              z @$mapButton,
                text: @model.l.get 'newPlaceInitialInfo.coordinatesFromMap'
                onclick: =>
                  @model.overlay.open new CoordinatePickerOverlay {
                    @model, @router, center
                    onPick: (location) =>
                      @locationValueStreams.next RxObservable.of (
                        "#{Math.round(location.location.lat * 10000) / 10000}, " +
                        "#{Math.round(location.location.lon * 10000) / 10000}"
                      )
                      Promise.resolve null
                    initialZoom: 9
                  }

            z '.field.amenities',
              z '.name', @model.l.get 'newAmenity.amenities'
              _map @amenities, (amenity) =>
                {amenity, valueSubject, hasPrice, $checkbox, $priceInput} = amenity
                isPriceInputVisible = hasPrice and valueSubject.getValue()
                z '.amenity',
                  z 'label.label',
                    z '.checkbox', z $checkbox
                    z '.name', @model.l.get "amenities.#{amenity}"
                  z '.price-input', {
                    className: z.classKebab {isVisible: isPriceInputVisible}
                  },
                    z $priceInput,
                      hintText: @model.l.get 'general.price'
                      type: 'number'
        ]
