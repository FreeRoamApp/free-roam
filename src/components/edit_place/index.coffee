z = require 'zorium'
_find = require 'lodash/find'
RxReplaySubject = require('rxjs/ReplaySubject').ReplaySubject

PrimaryButton = require '../primary_button'
PrimaryInput = require '../primary_input'
SecondaryButton = require '../secondary_button'
DuplicatePlaceDialog = require '../duplicate_place_dialog'
colors = require '../../colors'
config = require '../../config'

if window?
  require './index.styl'

module.exports = class EditPlace
  constructor: ({@model, @router, @place}) ->
    me = @model.user.getMe()

    @$duplicateButton = new SecondaryButton()
    @$saveButton = new PrimaryButton()


    @priceValueStreams = new RxReplaySubject 1
    @$priceInput = new PrimaryInput {
      valueStreams: @priceValueStreams
    }

    @resetValueStreams()

    @$initialInfo = new @NewPlaceInitialInfo {
      @model, @router, fields: @initialInfoFields
    }

    @state = z.state {
      me: @model.user.getMe()
      isLoading: false
      place: @place
      nameValue: @initialInfoFields.name.valueStreams.switch()
      detailsValue: @initialInfoFields.details.valueStreams.switch()
      locationValue: @initialInfoFields.location.valueStreams.switch()
      subTypeValue: @initialInfoFields.subType?.valueStreams.switch()
      priceValue: @priceValueStreams.switch()
    }

  upsert: =>
    {me, place, nameValue, detailsValue, locationValue,
      subTypeValue, priceValue} = @state.getValue()

    @state.set isLoading: true

    @model.user.requestLoginIfGuest me
    .then =>
      priceValue = parseInt priceValue
      if isNaN priceValue
        priceValue = 0

      @placeModel.upsert {
        id: place.id
        slug: place.slug
        name: nameValue
        details: detailsValue
        location: locationValue
        subType: subTypeValue
        prices:
          all:
            mode: priceValue
      }
      .catch (err) =>
        err = try
          JSON.parse err.message
        catch
          {}
        console.log err
        errorSubject = switch err.info.field
          when 'location' then @initialInfoFields.location.errorSubject
          when 'body' then @reviewFields.body.errorSubject
          else @initialInfoFields.location.errorSubject
        errorSubject.next @model.l.get err.info.langKey
        @state.set isLoading: false
      .then =>
        @router.back()
        @state.set isLoading: false

  beforeUnmount: =>
    @resetValueStreams()

  resetValueStreams: =>
    @initialInfoFields.name.valueStreams.next @place.map (place) ->
      place.name or ''
    @initialInfoFields.details.valueStreams.next @place.map (place) ->
      place.details or ''
    @initialInfoFields.location.valueStreams.next @place.map (place) ->
      location = "#{Math.round(place.location.lat * 10000) / 10000}, " +
      "#{Math.round(place.location.lon * 10000) / 10000}"
      location or ''
    @priceValueStreams.next @place.map (place) ->
      place.prices?.all?.mode or 0

    @initialInfoFields.subType?.valueStreams.next @place.map (place) ->
      place.subType or ''
    @initialInfoFields.agency?.valueStreams.next @place.map (place) ->
      place.agencySlug or ''
    @initialInfoFields.region?.valueStreams.next @place.map (place) ->
      place.regionSlug or ''
    @initialInfoFields.office?.valueStreams.next @place.map (place) ->
      place.officeSlug or ''

  render: =>
    {place, isLoading} = @state.getValue()

    z '.z-edit-place',
      # z @$duplicateButton,
      #   text: @model.l.get 'editPlace.markAsDupe'
      #   onclick: =>
      #     @model.overlay.open new DuplicatePlaceDialog {
      #       @model, @router, place
      #     }
      z '.g-grid',
        z @$initialInfo

        if place?.type is 'campground'
          z '.input',
            z @$priceInput, {
              hintText: @model.l.get 'general.price'
              type: 'number'
            }

        z @$saveButton,
          text: if isLoading \
                then @model.l.get 'general.loading'
                else @model.l.get 'general.save'
          onclick: @upsert
