z = require 'zorium'
RxBehaviorSubject = require('rxjs/BehaviorSubject').BehaviorSubject
_filter = require 'lodash/filter'
_map = require 'lodash/map'

PrimaryInput = require '../primary_input'
SecondaryButton = require '../secondary_button'
colors = require '../../colors'
config = require '../../config'

if window?
  require './index.styl'

DEFAULT_PHOTOS = [
  ''
  ''
  ''
  ''
  ''
]

module.exports = class NewMvum
  constructor: ({@model, @router, center}) ->
    me = @model.user.getMe()

    @nameValue = new RxBehaviorSubject ''
    @nameError = new RxBehaviorSubject null
    @$nameInput = new PrimaryInput
      value: @nameValue
      error: @nameError

    @$saveButton = new SecondaryButton()

    @state = z.state {
      isLoading: false
      photo: null
    }

  upsert: (e) =>
    {isLoading, photo} = @state.getValue()
    unless isLoading
      @state.set isLoading: true
      @nameError.next null

      @model.trip.upsert {
        type: 'custom'
        name: @nameValue.getValue()
      }
      .then (trip) =>
        @state.set {isLoading: false}
        @nameValue.next ''
        setTimeout =>
          @router.go 'trip', {
            id: trip.id
          }
        , 0
      .catch (err) =>
        err = try
          JSON.parse err.message
        catch
          {}
        console.log err
        errorSubject = switch err.info?.field
          when 'name' then @nameError
          else @nameError
        errorSubject.next err.info?.message or 'Error'

        @state.set isLoading: false
        alert 'Error'

  render: =>
    {isLoading} = @state.getValue()

    z '.z-new-trip',
      z '.g-grid',
        z 'label.field',
          z @$nameInput,
            hintText: @model.l.get 'newTrip.title'

        z '.photos-description',
          @model.l.get 'newTrip.photosDescription'
        z '.photos.g-grid',
          z '.g-cols',
            [
              _map DEFAULT_PHOTOS, (photoUrl) =>
                z '.g-col.g-xs-6.g-md-4',
                  z '.photo'
              z '.g-col.g-xs-6.g-md-4',
                z '.photo.upload',
                  z '.text', @model.l.get 'newTrip.upload'
            ]

        z '.actions',
          z @$saveButton,
            text: if isLoading \
                  then @model.l.get 'general.loading'
                  else @model.l.get 'general.create'
            onclick: @upsert
