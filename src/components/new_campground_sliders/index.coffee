z = require 'zorium'
RxBehaviorSubject = require('rxjs/BehaviorSubject').BehaviorSubject
_map = require 'lodash/map'
_every = require 'lodash/every'

InputRange = require '../input_range'
colors = require '../../colors'
config = require '../../config'

if window?
  require './index.styl'

module.exports = class NewCampgroundSliders
  constructor: ({@model, @router, @fields, @season, @overlay$}) ->
    me = @model.user.getMe()

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
    _every @sliders, ({valueSubject}) ->
      valueSubject.getValue()

  render: =>
    {season} = @state.getValue()

    z '.z-new-campground-sliders',
      z '.g-grid',
        _map @sliders, ({field, valueSubject, $range}) =>
          z '.field',
            z '.name', @model.l.get "campground.#{field}"
            $range
            @model.l.get "levelText.#{field}#{valueSubject.getValue()}"
