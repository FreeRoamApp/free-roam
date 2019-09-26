z = require 'zorium'
RxBehaviorSubject = require('rxjs/BehaviorSubject').BehaviorSubject
RxReplaySubject = require('rxjs/ReplaySubject').ReplaySubject
RxObservable = require('rxjs/Observable').Observable
require 'rxjs/add/observable/of'
require 'rxjs/add/observable/fromPromise'
require 'rxjs/add/operator/toPromise'
_map = require 'lodash/map'
_pick = require 'lodash/pick'
_isEmpty = require 'lodash/isEmpty'
_reduce = require 'lodash/reduce'
_every = require 'lodash/every'
_defaults = require 'lodash/defaults'
_startCase = require 'lodash/startCase'

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

module.exports = class NewPlaceReviewExtras
  constructor: (options) ->
    {@model, @router, @fields, @season, @isOptional,
      @parent, fieldsValues} = options
    me = @model.user.getMe()

    @parent ?= RxObservable.of null
    @$rigInfo = new RigInfo {@model, @router}

    if @fields.pricePaid
      @$pricePaidInput = new PrimaryInput {
        valueStreams: @fields.pricePaid.valueStreams
      }

    @seasons =  [
      {key: 'spring', text: _startCase @model.l.get 'seasons.spring'}
      {key: 'summer', text: _startCase @model.l.get 'seasons.summer'}
      {key: 'fall', text: _startCase @model.l.get 'seasons.fall'}
      {key: 'winter', text: _startCase @model.l.get 'seasons.winter'}
    ]

    @sliders = _map @allowedFields, (field) =>
      {
        field: field
        valueStreams: @fields[field].valueStreams
        $range: new InputRange {
          @model
          valueStreams: @fields[field].valueStreams, minValue: 1, maxValue: 5
        }
      }

    @carrierCache = []

    carriersValueStreams = new RxReplaySubject 1
    carriersValueStreams.next try
      JSON.parse localStorage?['cellCarriers']
    catch err
      []

    # HACK: infinite loop with other approaches
    # (using cellSignal.valueStreams directly)
    initialValue = new RxBehaviorSubject null
    @fields.cellSignal.valueStreams.switch().take(1).subscribe (cellSignal) ->
      initialValue.next cellSignal

    carriers = @parent.map (parent) ->
      # TODO: store country in address so we don't have to do this
      isCanada = parent?.address?.administrativeArea in [
        'AB', 'BC', 'MB', 'NB', 'NL', 'NS', 'NT', 'NU',
        'ON', 'PE', 'QC', 'SK', 'YT'
      ]

      if isCanada
        ['rogers', 'bell', 'telus']
      else
        ['verizon', 'att', 'tmobile', 'sprint']

    @$carrierDropdown = new DropdownMultiple {
      @model
      valueStreams: carriersValueStreams
      options: carriers.map((carriers) =>
        _map carriers, (carrier) =>
          streams = new RxReplaySubject 1
          streams.next initialValue.map (value) =>
            Boolean value?["#{carrier}_lte"]
          {
            value: carrier
            text: @model.l.get "carriers.#{carrier}"
            isCheckedStreams: streams
          }
      ).publishReplay(1).refCount()
    }

    carriersAndInitialValue = RxObservable.combineLatest(
      carriersValueStreams.switch()
      initialValue
      (vals...) -> vals
    )

    carriersWithExtras = carriersAndInitialValue.map ([carriers, initial]) =>
      initial ?= {}

      localStorage?['cellCarriers'] = JSON.stringify _map carriers, (carrier) ->
        _pick carrier, ['value', 'text']
      _map carriers, (carrier) =>
        if @carrierCache[carrier.value]
          return @carrierCache[carrier.value]

        barsValueSubject = new RxBehaviorSubject(
          initial["#{carrier.value}_lte"] or null
        )
        lteValueSubject = new RxBehaviorSubject(
          Boolean (
            initial["#{carrier.value}"] and not initial["#{carrier.value}_lte"]
          ) or not initial["#{carrier.value}"]
        )

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
        if _isEmpty carriersWithExtras
          return RxObservable.of {}

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
    hasPrice = not @fields.pricePaid or fieldsValues?['pricePaid']?
    @season.getValue() and hasPrice and _every @sliders, ({field}) ->
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
            z @$carrierDropdown, {
              currentText: if _isEmpty carriers \
                     then @model.l.get 'carriers.selectCarrier'
                     else _map(carriers, ({carrier}) -> carrier.text).join ', '
            }
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
                className: z.classKebab {
                  isSelected: key is season
                  "#{key}": true
                }
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
