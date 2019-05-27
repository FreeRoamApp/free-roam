z = require 'zorium'
_find = require 'lodash/find'

PrimaryButton = require '../primary_button'
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
    }

  upsert: =>
    {me, place, nameValue, detailsValue, locationValue,
      subTypeValue} = @state.getValue()

    @state.set isLoading: true

    @model.user.requestLoginIfGuest me
    .then =>
      @placeModel.upsert {
        id: place.id
        slug: place.slug
        name: nameValue
        details: detailsValue
        location: locationValue
        subType: subTypeValue
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
        @state.set isLoading: false

  beforeUnmount: =>
    @resetValueStreams()

  resetValueStreams: =>
    @initialInfoFields.name.valueStreams.next @place.map (place) ->
      console.log 'plac', place
      place.name or ''
    @initialInfoFields.details.valueStreams.next @place.map (place) ->
      place.details or ''
    @initialInfoFields.location.valueStreams.next @place.map (place) ->
      location = "#{Math.round(place.location.lat * 10000) / 10000}, " +
      "#{Math.round(place.location.lon * 10000) / 10000}"
      location or ''

  render: =>
    {place, isLoading} = @state.getValue()

    z '.z-edit-place',
      z @$duplicateButton,
        text: @model.l.get 'editPlace.markAsDupe'
        onclick: =>
          @model.overlay.open new DuplicatePlaceDialog {
            @model, @router, place
          }

      z @$initialInfo

      z @$saveButton,
        text: @model.l.get 'general.save'
        onclick: @upsert
