z = require 'zorium'
RxBehaviorSubject = require('rxjs/BehaviorSubject').BehaviorSubject
_map = require 'lodash/map'
_every = require 'lodash/every'

InputRange = require '../input_range'
colors = require '../../colors'
config = require '../../config'

if window?
  require './index.styl'

module.exports = class NewReviewExtras
  constructor: ({@model, @router, @fields, @season, @overlay$}) ->
    me = @model.user.getMe()

    @seasons =  [
      {key: 'spring', text: @model.l.get 'seasons.spring'}
      {key: 'summer', text: @model.l.get 'seasons.summer'}
      {key: 'fall', text: @model.l.get 'seasons.fall'}
      {key: 'winter', text: @model.l.get 'seasons.winter'}
    ]

    fields = ['roadDifficulty', 'crowds', 'fullness', 'noise', 'shade',
              'safety']
    @sliders = _map fields, (field) =>
      {
        field: field
        valueSubject: @fields[field].valueSubject
        $range: new InputRange {
          value: @fields[field].valueSubject, minValue: 1, maxValue: 5
        }
      }

    @state = z.state {
      @season
    }

  isCompleted: =>
    @season.getValue() and _every @sliders, ({valueSubject}) ->
      valueSubject.getValue()

  render: =>
    {season} = @state.getValue()

    z '.z-new-review-extras',
      z '.g-grid',
        z '.field.when',
          z '.name', @model.l.get 'newCampgroundInitialInfo.whenVisit'
          z '.seasons',
            _map @seasons, ({key, text}) =>
              z '.season', {
                className: z.classKebab {isSelected: key is season}
                onclick: =>
                  @season.next key
              }, text
        _map @sliders, ({field, valueSubject, $range}) =>
          z '.field',
            z '.name', @model.l.get "campground.#{field}"
            $range
            @model.l.get "levelText.#{field}#{valueSubject.getValue()}"
