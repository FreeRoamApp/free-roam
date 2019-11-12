z = require 'zorium'
RxBehaviorSubject = require('rxjs/BehaviorSubject').BehaviorSubject
RxReplaySubject = require('rxjs/ReplaySubject').ReplaySubject
RxObservable = require('rxjs/Observable').Observable
require 'rxjs/add/observable/of'
_map = require 'lodash/map'
_pick = require 'lodash/pick'
_isEmpty = require 'lodash/isEmpty'
_isEqual = require 'lodash/isEqual'
_reduce = require 'lodash/reduce'

CellBars = require '../cell_bars'
Checkbox = require '../checkbox'
Icon = require '../icon'
colors = require '../../colors'

if window?
  require './index.styl'

MAX_BARS = 5

# FIXME: initial value when editing review
module.exports = class CellSelector
  # set isInteractive to true if tapping on a star should fill up to that star
  constructor: ({@model, carriers, @valueStreams, useLocalStorage}) ->
    @carrierCache = []

    @selectedCarriersStreams = new RxReplaySubject 1
    if useLocalStorage
      @selectedCarriersStreams.next RxObservable.of try
        JSON.parse localStorage?['selectedCellCarriers']
      catch err
        []
    else
      @selectedCarriersStreams.next RxObservable.of []

    @signalsStreams = new RxReplaySubject 1

    @state = z.state {
      carriers: carriers
      selectedCarriers: @selectedCarriersStreams.switch()
      value: @valueStreams.switch()
      signals: @signalsStreams.switch()
    }

  afterMount: =>
    updateValue = new RxBehaviorSubject null

    carriersAndInitialValue = RxObservable.combineLatest(
      @selectedCarriersStreams.switch()
      updateValue
      (vals...) -> vals
    )

    isInitial = true
    # HACK: infinite loop with other approaches
    # (using @valueStreams directly)
    currentValue = null
    @disposable = @valueStreams.switch().subscribe (cellSignal) =>
      console.warn 'cell selector subscription call', cellSignal
      if not _isEqual cellSignal, currentValue
        currentValue = cellSignal
        updateValue.next cellSignal
        @selectedCarriersStreams.next RxObservable.of(
          _map cellSignal, (val, key) -> key.replace '_lte', ''
        )
      # else if cellSignal is null
      #   @selectedCarriersStreams.next RxObservable.of []


    signals = carriersAndInitialValue.map ([carriers, updateValue]) =>
      updateValue ?= {}

      localStorage?['selectedCellCarriers'] = JSON.stringify carriers

      _map carriers, (carrier) =>
        if @carrierCache[carrier]
          return @carrierCache[carrier]

        barsValueSubject = new RxBehaviorSubject(
          updateValue["#{carrier}_lte"] or updateValue[carrier] or 3
        )
        lteValueSubject = new RxBehaviorSubject(
          Boolean (
            not updateValue[carrier] and updateValue["#{carrier}_lte"]
          ) or not updateValue[carrier]
        )

        @carrierCache[carrier] = {
          carrier
          barsValueSubject
          lteValueSubject
          $lteCheckbox: new Checkbox {value: lteValueSubject}
          $bars: new CellBars {
            value: barsValueSubject, isInteractive: true
            includeNoSignal: true
          }
        }

    @signalsStreams.next signals

    @valueStreams.next(
      signals.switchMap (signals) ->
        if _isEmpty signals
          return RxObservable.of undefined # HACK: needs to be undefined so subscription above doesn't infinite loop

        barsChangesFeed = RxObservable.combineLatest(
          _map signals, 'barsValueSubject'
          (vals...) -> vals
        )
        lteChangesFeed = RxObservable.combineLatest(
          _map signals, 'lteValueSubject'
          (vals...) -> vals
        )
        changesFeed = RxObservable.combineLatest(
          barsChangesFeed, lteChangesFeed, (vals...) -> vals
        )

        changesFeed.map (changes) ->
          _reduce signals, (obj, carrierWithExtras) ->
            {carrier, barsValueSubject, lteValueSubject} = carrierWithExtras
            key = carrier
            if lteValueSubject.getValue()
              key += '_lte'
            if barsValueSubject.getValue()?
              obj[key] = barsValueSubject.getValue()
            obj
          , {}

    )



  beforeUnmount: =>
    @disposable?.unsubscribe()

  reset: =>
    @carrierCache = []

  render: ({label} = {}) =>
    {carriers, signals, selectedCarriers, value} = @state.getValue()

    z '.z-cell-selector',
      z '.carriers',
        _map carriers, (carrier) =>
          isSelected = selectedCarriers.indexOf(carrier) isnt -1
          z '.carrier', {
            className: z.classKebab {isSelected}
            onclick: =>
              if isSelected
                newSelectedCarriers = selectedCarriers
                index = newSelectedCarriers.indexOf(carrier)
                newSelectedCarriers.splice index, 1
              else
                newSelectedCarriers = (selectedCarriers or []).concat [
                  carrier
                ]
              @selectedCarriersStreams.next RxObservable.of newSelectedCarriers
          },
            @model.l.get "carriers.#{carrier}"

      if label and not _isEmpty signals
        z '.label', label

      z '.signals',
          _map signals, (signal) =>
            {carrier, $bars, $lteCheckbox} = signal

            z '.signal',
              z '.bars',
                z $bars, {widthPx: 112}
              z '.name',
                @model.l.get "carriers.#{carrier}"
              z 'label.lte',
                z '.text',
                  @model.l.get 'newReviewExtras.hasLte'
                z '.checkbox',
                  z $lteCheckbox, {
                    colors:
                      checked: colors.$secondaryMain
                      checkedBorder: colors.$secondary900
                  }
