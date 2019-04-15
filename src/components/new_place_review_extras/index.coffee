z = require 'zorium'
RxBehaviorSubject = require('rxjs/BehaviorSubject').BehaviorSubject
RxReplaySubject = require('rxjs/ReplaySubject').ReplaySubject
RxObservable = require('rxjs/Observable').Observable
require 'rxjs/add/observable/of'
_map = require 'lodash/map'
_mapValues = require 'lodash/mapValues'
_range = require 'lodash/range'
_reduce = require 'lodash/reduce'
_every = require 'lodash/every'
_defaults = require 'lodash/defaults'

CellBars = require '../cell_bars'
Checkbox = require '../checkbox'
DropdownMultiple = require '../dropdown_multiple'
InputRange = require '../input_range'
PrimaryButton = require '../primary_button'
PrimaryInput = require '../primary_input'
RigInfo = require '../rig_info'
colors = require '../../colors'
config = require '../../config'

if window?
  require './index.styl'

module.exports = class PlaceNewReviewExtras
  constructor: (options) ->
    {@model, @router, @fields, @season, @isOptional, fieldsValues} = options
    me = @model.user.getMe()

    @$rigInfo = new RigInfo {@model, @router}

    if @fields.pricePaid
      @$pricePaidInput = new PrimaryInput {
        valueStreams: @fields.pricePaid.valueStreams
      }

    @seasons =  [
      {key: 'spring', text: @model.l.get 'seasons.spring'}
      {key: 'summer', text: @model.l.get 'seasons.summer'}
      {key: 'fall', text: @model.l.get 'seasons.fall'}
      {key: 'winter', text: @model.l.get 'seasons.winter'}
    ]

    @sliders = _map @allowedFields, (field) =>
      {
        field: field
        valueStreams: @fields[field].valueStreams
        $range: new InputRange {
          valueStreams: @fields[field].valueStreams, minValue: 1, maxValue: 5
        }
      }

    @carrierCache = []

    carriersValueStreams = new RxReplaySubject 1
    @$carrierDropdown = new DropdownMultiple {
      @model
      valueStreams: carriersValueStreams
      options: [
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
    }

    carriersWithExtras = carriersValueStreams.switch().map (carriers) =>
      _map carriers, (carrier) =>
        if @carrierCache[carrier.value]
          return @carrierCache[carrier.value]

        # TODO: use cellSignal valueStreams when editing review
        barsValueSubject = new RxBehaviorSubject null
        lteValueSubject = new RxBehaviorSubject true

        @carrierCache[carrier.value] = {
          carrier
          barsValueSubject
          lteValueSubject
          $lteCheckbox: new Checkbox {value: lteValueSubject}
          $bars: new CellBars {
            value: barsValueSubject, isInteractive: true
            includeNoSignal: true
          }
        }

    @fields.cellSignal.valueStreams.next(
      carriersWithExtras.switchMap (carriersWithExtras) ->
        barsChangesFeed = RxObservable.combineLatest(
          _map carriersWithExtras, 'barsValueSubject'
          (vals...) -> vals
        )
        lteChangesFeed = RxObservable.combineLatest(
          _map carriersWithExtras, 'lteValueSubject'
          (vals...) -> vals
        )
        changesFeed = RxObservable.combineLatest(
          barsChangesFeed, lteChangesFeed, (vals...) -> vals
        )

        changesFeed.map (changes) ->
          _reduce carriersWithExtras, (obj, carrierWithExtras) ->
            {carrier, barsValueSubject, lteValueSubject} = carrierWithExtras
            key = carrier.value
            if lteValueSubject.getValue()
              key += '_lte'
            obj[key] = barsValueSubject.getValue()
            obj
          , {}

    )

    @state = z.state {
      @season
      me: @model.user.getMe()
      fieldsValues: fieldsValues
      carriers: carriersWithExtras
    }

  reset: =>
    @carrierCache = []

  isCompleted: =>
    {me, fieldsValues} = @state.getValue()
    if @isOptional or me?.username is 'austin'
      return true
    @season.getValue() and _every @sliders, ({field}) ->
      fieldsValues?[field]

  getTitle: =>
    @model.l.get 'newReviewExtras.title'

  render: =>
    {season, carriers, fieldsValues} = @state.getValue()

    z '.z-place-new-review-extras',
      z '.g-grid',

        z '.field',
          z @$rigInfo

        if @fields.pricePaid
          z '.field.price',
            z '.name', @model.l.get 'newReviewExtras.howMuch'
            z '.input',
              z @$pricePaidInput, {
                hintText: @model.l.get 'newReviewExtras.pricePaid'
                type: 'number'
              }

        z '.field.cell',
          z '.name', @model.l.get 'newReviewExtras.cellSignal'
          z '.dropdown',
            z @$carrierDropdown
          z '.carriers',
              _map carriers, (carrier) =>
                {carrier, $bars, $lteCheckbox} = carrier

                z '.carrier',
                  z '.bars',
                    z $bars, {widthPx: 100}
                  z '.name',
                    carrier.text
                  z 'label.lte',
                    z '.checkbox',
                      z $lteCheckbox, {
                        colors:
                          checked: colors.$secondary500
                          checkedBorder: colors.$secondary900
                      }
                    z '.text',
                      @model.l.get 'newReviewExtras.hasLte'

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
                  if fieldsValues?[field]
                    @model.l.get "levelText.#{field}#{fieldsValues[field]}"
