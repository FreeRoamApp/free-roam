z = require 'zorium'
RxBehaviorSubject = require('rxjs/BehaviorSubject').BehaviorSubject
_map = require 'lodash/map'
_mapValues = require 'lodash/mapValues'
_range = require 'lodash/range'
_reduce = require 'lodash/reduce'
_every = require 'lodash/every'
_defaults = require 'lodash/defaults'

CellBars = require '../cell_bars'
Checkbox = require '../checkbox'
Dropdown = require '../dropdown'
InputRange = require '../input_range'
PrimaryButton = require '../primary_button'
colors = require '../../colors'
config = require '../../config'

if window?
  require './index.styl'

module.exports = class NewReviewExtras
  constructor: ({@model, @router, @fields, @season, @overlay$, @isOptional}) ->
    me = @model.user.getMe()

    @$addCarrierButton = new PrimaryButton()

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

    @carrierCount = new RxBehaviorSubject 1

    # FIXME FIXME rm
    # setInterval =>
    #   console.log 'cell change'
    #   @onCellChange()
    # , 1000

    @carrierCache = []
    @disposables = []

    @state = z.state {
      @season
      carrierCount: @carrierCount
      carriers: @carrierCount.map (count) =>
        _map _range(count), (i) =>
          if @carrierCache[i]
            return @carrierCache[i]
          initialCarrier = @model.cookie.get('cellCarrier') or 'placeholder'
          carrierValueSubject = new RxBehaviorSubject(initialCarrier)
          @disposables.push carrierValueSubject.subscribe (carrier) =>
            @model.cookie.set 'cellCarrier', carrier
            @onCellChange()
          barsValueSubject = new RxBehaviorSubject null
          @disposables.push barsValueSubject.subscribe @onCellChange
          lteValueSubject = new RxBehaviorSubject true
          @disposables.push lteValueSubject.subscribe @onCellChange

          @carrierCache[i] = {
            carrierValueSubject
            barsValueSubject
            lteValueSubject
            $lteCheckbox: new Checkbox {value: lteValueSubject}
            $carrierDropdown: new Dropdown {value: carrierValueSubject}
            $bars: new CellBars {
              value: barsValueSubject, isInteractive: true
              includeNoSignal: true
            }
          }
    }

  onCellChange: =>
    setImmediate =>
      {carriers} = @state.getValue()
      unless carriers
        return
      carrierCount = @carrierCount.getValue()
      newCellSignal = _reduce _range(carrierCount), (obj, value, i) ->
        {carrierValueSubject, barsValueSubject, lteValueSubject} = carriers[i]

        carrier = carrierValueSubject.getValue()
        signal = barsValueSubject.getValue()
        isLte = lteValueSubject.getValue()
        key = if isLte then "#{carrier}_lte" else carrier
        if signal? and carrier isnt 'placeholder'
          obj[key] = signal
        obj
      , {}

      console.log newCellSignal

      @fields.cellSignal.valueSubject.next newCellSignal

  isCompleted: =>
    if @isOptional
      return true
    @season.getValue() and _every @sliders, ({valueSubject}) ->
      valueSubject.getValue()

  beforeUnmount: =>
    _map @disposables, (disposable) -> disposable?.unsubscribe?()

  getTitle: =>
    @model.l.get 'newReviewExtras.title'

  render: =>
    {season, carriers} = @state.getValue()

    z '.z-new-review-extras',
      z '.g-grid',
        z '.field.cell',
          z '.name', @model.l.get 'newReviewExtras.cellSignal'
          z '.carriers',
            [
              _map carriers, (carrier) =>
                {carrier, $bars, $carrierDropdown, $lteCheckbox} = carrier
                z '.carrier',
                  z '.dropdown',
                    z $carrierDropdown,
                      options: [
                        {
                          value: 'placeholder'
                          text: @model.l.get 'carriers.selectCarrier'
                        }
                        {
                          value: 'verizon'
                          text: @model.l.get 'carriers.verizon'
                        }
                        {value: 'att', text: @model.l.get 'carriers.att'}
                        {
                          value: 'tmobile'
                          text: @model.l.get 'carriers.tmobile'
                        }
                        {value: 'sprint', text: @model.l.get 'carriers.sprint'}
                      ]
                  z '.bars',
                    z $bars, {widthPx: 200}
                  z 'label.lte',
                    z '.checkbox',
                      z $lteCheckbox
                    @model.l.get 'newReviewExtras.hasLte'
              z '.add-carrier',
                z @$addCarrierButton,
                  text: @model.l.get 'newReviewExtras.addCarrier'
                  onclick: =>
                    @carrierCount.next @carrierCount.getValue() + 1
            ]
        z '.field.when',
          z '.name', @model.l.get 'newReviewExtras.whenVisit'
          z '.seasons',
            _map @seasons, ({key, text}) =>
              z '.season', {
                className: z.classKebab {isSelected: key is season}
                onclick: =>
                  @season.next key
              }, text
        z '.g-grid',
          z '.g-cols',
            _map @sliders, ({field, valueSubject, $range}) =>
              z '.g-col.g-xs-12.g-md-6',
                z '.field',
                  z '.name', @model.l.get "campground.#{field}"
                  $range
                  if valueSubject.getValue()?
                    @model.l.get "levelText.#{field}#{valueSubject.getValue()}"
