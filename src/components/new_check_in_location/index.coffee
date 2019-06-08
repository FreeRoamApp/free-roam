z = require 'zorium'
RxBehaviorSubject = require('rxjs/BehaviorSubject').BehaviorSubject
RxReplaySubject = require('rxjs/ReplaySubject').ReplaySubject
RxObservable = require('rxjs/Observable').Observable
_filter = require 'lodash/filter'
_find = require 'lodash/find'

CoordinatePicker = require '../coordinate_picker'
PrimaryInput = require '../primary_input'
UploadImagesList = require '../upload_images_list'
Icon = require '../icon'
DateService = require '../../services/date'
colors = require '../../colors'
config = require '../../config'

if window?
  require './index.styl'

module.exports = class NewCheckInLocation
  constructor: ({@model, @router, @checkIn, @fields, @step}) ->
    placeStreams = new RxReplaySubject 1
    placeStreams.next @checkIn.map (checkIn) ->
      checkIn?.place
    @$coordinatePicker = new CoordinatePicker {
      @model, @router, placeStreams, onPick: (place) =>
        (if place.type is 'coordinate' or not place.type
          @model.coordinate.upsert {
            name: place.name
            location: "#{place.location.lat}, #{place.location.lon}"
          }, {invalidateAll: false}
        else
          Promise.resolve {id: place.id}
        ).then ({id}) =>
          @step.next @step.getValue() + 1
          {name} = @state.getValue()
          if place.name and not name
            @fields.name.valueStreams.next RxObservable.of place.name
          @fields.source.valueStreams.next RxObservable.of {
            sourceType: place.type, sourceId: id
          }
    }

    @state = z.state {
      name: @fields.name.valueStreams.switch()
      source: @fields.source.valueStreams.switch()
    }

  isCompleted: =>
    {source} = @state.getValue()
    source?.sourceId

  render: =>
    {isLoading} = @state.getValue()

    z '.z-new-check-in-location',
      z @$coordinatePicker
