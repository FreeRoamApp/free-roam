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
  constructor: ({@model, @router, @fields, @season, @overlay$}) ->
    me = @model.user.getMe()

    @$nameInput = new PrimaryInput
      value: @fields.name.valueSubject
      error: @fields.name.errorSubject

    @$locationInput = new PrimaryInput
      value: @fields.location.valueSubject
      error: @fields.location.errorSubject

    @$mapButton = new PrimaryButton()

    @seasons =  [
      {key: 'spring', text: @model.l.get 'seasons.spring'}
      {key: 'summer', text: @model.l.get 'seasons.summer'}
      {key: 'fall', text: @model.l.get 'seasons.fall'}
      {key: 'winter', text: @model.l.get 'seasons.winter'}
    ]

    @state = z.state {
      @season
    }

  isCompleted: =>
    @fields.name.valueSubject.getValue() and
      @fields.location.valueSubject.getValue() and
      @season.getValue()


  render: =>
    {season} = @state.getValue()

    z '.z-new-campground-initial-info',
      z '.g-grid',
        z 'label.field',
          z '.name', @model.l.get 'newCampgroundInitialInfo.campgroundName'
          z @$nameInput,
            hintText: @model.l.get 'newCampgroundInitialInfo.campgroundName'

        z '.field.when',
          z '.name', @model.l.get 'newCampgroundInitialInfo.whenVisit'
          z '.seasons',
            _map @seasons, ({key, text}) =>
              z '.season', {
                className: z.classKebab {isSelected: key is season}
                onclick: =>
                  @season.next key
              }, text

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
