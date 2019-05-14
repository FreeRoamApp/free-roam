z = require 'zorium'
RxBehaviorSubject = require('rxjs/BehaviorSubject').BehaviorSubject
RxObservable = require('rxjs/Observable').Observable
require 'rxjs/add/observable/combineLatest'
require 'rxjs/add/observable/of'
_map = require 'lodash/map'
_filter = require 'lodash/filter'
_range = require 'lodash/range'
_startCase = require 'lodash/startCase'
_zipObject = require 'lodash/zipObject'

Dialog = require '../dialog'
Dropdown = require '../dropdown'
Checkbox = require '../checkbox'
CellBars = require '../cell_bars'
PrimaryInput = require '../primary_input'
InputRange = require '../input_range'
colors = require '../../colors'
config = require '../../config'

if window?
  require './index.styl'

module.exports = class FilterDialog
  constructor: ({@model, @filter}) ->
    @$dialog = new Dialog {
      onLeave: =>
        @model.overlay.close()
    }

    switch @filter.type
      when 'maxIntCustom', 'minIntCustom'
        filterValue = new RxBehaviorSubject @filter.value or ''
        @$input = new PrimaryInput {value: filterValue}
      when 'maxInt'
        filterValue = new RxBehaviorSubject @filter.value or 5
        @$inputRange = new InputRange {
          value: filterValue, minValue: 1, maxValue: 5
        }
      when 'minInt'
        filterValue = new RxBehaviorSubject @filter.value or 1
        @$inputRange = new InputRange {
          value: filterValue, minValue: 1, maxValue: 5
        }
      when 'maxIntSeasonal'
        seasonValue = new RxBehaviorSubject @model.time.getCurrentSeason()
        rangeValue = new RxBehaviorSubject @filter.value?.value or 5
        @$inputRange = new InputRange {
          value: rangeValue, minValue: 1, maxValue: 5
        }
        filterValue = RxObservable.combineLatest(
          seasonValue, rangeValue, (vals...) -> vals
        ).map ([season, value]) ->
          {season, value}
      when 'maxIntDayNight'
        dayNight = new RxBehaviorSubject 'day'
        rangeValue = new RxBehaviorSubject @filter.value?.value or 5
        @$inputRange = new InputRange {
          value: rangeValue, minValue: 1, maxValue: 5
        }
        filterValue = RxObservable.combineLatest(
          dayNight, rangeValue, (vals...) -> vals
        ).map ([dayNight, value]) ->
          {dayNight, value}
      when 'maxClearance'
        feetValue = new RxBehaviorSubject @filter.value?.feet or '14'
        @$feetInput = new PrimaryInput {value: feetValue}

        inchesValue = new RxBehaviorSubject @filter.value?.inches or '6'
        @$inchesInput = new PrimaryInput {value: inchesValue}

        filterValue = RxObservable.combineLatest(
          feetValue
          inchesValue
          (vals...) -> vals
        ).map ([feet, inches]) ->
          {feet, inches}
      when 'cellSignal'
        initialCarrier = @model.cookie.get('cellCarrier') or 'verizon'
        @carrierDropdownValue = new RxBehaviorSubject(initialCarrier)
        .do (carrier) =>
          @model.cookie.set 'cellCarrier', carrier
        @$carrierDropdown = new Dropdown {value: @carrierDropdownValue}

        @isLteValue = new RxBehaviorSubject(
          if @filter.value?.isLte?
          then @filter.value?.isLte
          else true # default true
        )
        @$isLteCheckbox = new Checkbox {value: @isLteValue}

        @cellBarsValue = new RxBehaviorSubject @filter.value?.signal or 3
        @$cellBars = new CellBars {value: @cellBarsValue, isInteractive: true}

        filterValue = RxObservable.combineLatest(
          @carrierDropdownValue
          @cellBarsValue
          @isLteValue
          (vals...) -> vals
        ).map ([carrier, signal, isLte]) ->
          {carrier, signal, isLte}
      when 'list', 'booleanArraySubTypes'
        list = @filter.items

        @checkboxes = _map list, ({key, label}) =>
          valueSubject = new RxBehaviorSubject(
            @filter.value?[key]
          )
          $checkbox = new Checkbox {value: valueSubject}
          {valueSubject, $checkbox, label}

        filterValue = RxObservable.combineLatest(
          _map @checkboxes, (item) -> item.valueSubject
          (vals...) -> vals
        ).map (vals) ->
          _zipObject _map(list, 'key'), vals

      when 'weather'
        forecastMetrics = [
          'maxHigh', 'minHigh', 'maxLow', 'minLow', 'rainyDays'
        ]
        @monthDropdownValue = new RxBehaviorSubject(
          if @filter.value?.month?
          then @filter.value?.month
          else new Date().getMonth()
        ).do (month) =>
          if month is 'forecast' and not (
            @filter.value?.metric in forecastMetrics
          )
            @metricDropdownValue.next 'maxHigh'
          # if using forecast metrics, switch back to avg metrics
          else if month isnt 'forecast' and
              @filter.value?.metric in forecastMetrics
            @metricDropdownValue.next 'tmin'

        @$monthDropdown = new Dropdown {value: @monthDropdownValue}

        @metricDropdownValue = new RxBehaviorSubject(
          @filter.value?.metric or 'tmin'
        ).do (metric) =>
          switch metric
            when 'maxHigh' then @operatorDropdownValue.next 'lt'
            when 'minHigh' then @operatorDropdownValue.next 'gt'
            when 'maxLow' then @operatorDropdownValue.next 'lt'
            when 'minLow' then @operatorDropdownValue.next 'gt'
            when 'rainyDays' then @operatorDropdownValue.next 'lt'
            when 'tmin' then @operatorDropdownValue.next 'gt'
            when 'tmax' then @operatorDropdownValue.next 'lt'
            when 'precip' then @operatorDropdownValue.next 'lt'
        @$metricDropdown = new Dropdown {value: @metricDropdownValue}

        @operatorDropdownValue = new RxBehaviorSubject(
          @filter.value?.operator or 'gt'
        )
        @$operatorDropdown = new Dropdown {value: @operatorDropdownValue}

        @numberValue = new RxBehaviorSubject @filter.value?.number or ''
        @$numberInput = new PrimaryInput {value: @numberValue}

        filterValue = RxObservable.combineLatest(
          @monthDropdownValue
          @metricDropdownValue
          @operatorDropdownValue
          @numberValue
          (vals...) -> vals
        ).map ([month, metric, operator, number]) ->
          {month, metric, operator, number}
      when 'distanceTo'
        @amenityDropdownValue = new RxBehaviorSubject(
          if @filter.value?.amenity?
          then @filter.value?.amenity
          else 'dump'
        )
        @$amenityDropdown = new Dropdown {value: @amenityDropdownValue}

        @timeValue = new RxBehaviorSubject @filter.value?.time or ''
        @$timeInput = new PrimaryInput {value: @timeValue}

        filterValue = RxObservable.combineLatest(
          @amenityDropdownValue
          @timeValue
          (vals...) -> vals
        ).map ([amenity, time]) ->
          {amenity, time}

    @state = z.state
      filterValue: filterValue

  render: =>
    {filterValue} = @state.getValue()

    switch @filter.type
      when 'maxInt', 'maxIntSeasonal', 'minInt', 'maxIntDayNight'
        value = filterValue?.value or filterValue
        $content =
          z '.content',
            z @$inputRange, {
              label: @model.l.get "filterDialog.#{@filter.field}Label"
            }
            @model.l.get "levelText.#{@filter.field}#{value}"
      when 'maxIntCustom', 'minIntCustom'
        $title = @model.l.get "campground.#{@filter.key}"
        $content =
          z '.content',
            z '.label', @model.l.get "filterDialog.#{@filter.key}"
            z '.fields',
              z @$input, {
                type: 'number'
                hintText:
                  @model.l.get "campground.#{@filter.key}"
              }
      when 'maxClearance'
        $title = @model.l.get 'lowClearance.maxClearance'
        $content =
          z '.content',
            z '.label', @model.l.get 'filterDialog.maxClearance'
            z '.fields',
              z @$feetInput, {
                type: 'number'
                hintText:
                  @model.l.get 'filterDialog.feet'
              }
              z @$inchesInput, {
                type: 'number'
                hintText:
                  @model.l.get 'filterDialog.inches'
              }
      when 'list', 'booleanArraySubTypes'
        $title = @filter?.name
        $content =
          z '.content',
            _map @checkboxes, ({$checkbox, label}) ->
              z 'label.checkbox-label',
                z '.checkbox',
                  z $checkbox
                z '.text', label or 'fixme'
      when 'cellSignal'
        $content =
          z '.content',
            z '.div', @model.l.get 'filterDialog.cellCarrier'
            z '.carrier',
              z @$carrierDropdown,
                options: [
                  {value: 'verizon', text: @model.l.get 'carriers.verizon'}
                  {value: 'att', text: @model.l.get 'carriers.att'}
                  {value: 'tmobile', text: @model.l.get 'carriers.tmobile'}
                  {value: 'sprint', text: @model.l.get 'carriers.sprint'}
                ]
            z '.label', @model.l.get 'filterDialog.minSignal'
            z '.bars', z @$cellBars, {widthPx: 200}
            z 'label.checkbox-label',
              z '.checkbox',
                z @$isLteCheckbox
              z '.text', @model.l.get 'filterDialog.requireLte'
      when 'weather'
        metric = filterValue?.metric
        $content =
          z '.content',
            z '.label', @model.l.get 'general.weather'
            z '.month',
              z @$monthDropdown,
                options: [
                  {
                    value: 'forecast'
                    text: @model.l.get 'filterDialog.weatherForecast'
                  }
                ].concat _map _range(12), (i) =>
                  {value: "#{i}", text: @model.l.get "months.#{i}"}
            z '.metric',
              z @$metricDropdown,
                options: if filterValue?.month is 'forecast'
                  [
                    {
                      value: 'maxHigh'
                      text: @model.l.get 'filterDialog.weatherMaxHigh'
                    }
                    {
                      value: 'minHigh'
                      text: @model.l.get 'filterDialog.weatherMinHigh'
                    }
                    {
                      value: 'maxLow'
                      text: @model.l.get 'filterDialog.weatherMaxLow'
                    }
                    {
                      value: 'minLow'
                      text: @model.l.get 'filterDialog.weatherMinLow'
                    }
                    {
                      value: 'rainyDays'
                      text: @model.l.get 'filterDialog.weatherRainyDays'
                    }
                  ]
                else
                  [
                    {
                      value: 'tmin'
                      text: @model.l.get 'filterDialog.weatherTmin'
                    }
                    {
                      value: 'tmax'
                      text: @model.l.get 'filterDialog.weatherTmax'
                    }
                    {
                      value: 'precip'
                      text: @model.l.get 'filterDialog.weatherPrecip'
                    }
                  ]
            z '.operator',
              z @$operatorDropdown,
                options: [
                  {
                    value: 'gt'
                    text: @model.l.get 'general.gt'
                  }
                  {
                    value: 'lt'
                    text: @model.l.get 'general.lt'
                  }
                ]
            z '.number',
              z @$numberInput, {
                type: 'number'
                hintText: @model.l.get(
                  "filterDialog.weather#{_startCase(metric).replace(/ /g, '')}"
                )
              }
      when 'distanceTo'
        $content =
          z '.content',
            z '.label', @model.l.get 'general.amenity'
            z '.amenity',
              z @$amenityDropdown,
                options: [
                  {value: 'dump', text: 'Dump Station'}
                  {value: 'water', text: 'Fresh Water'}
                  {value: 'groceries', text: 'Groceries'}
                ]
            z 'label.label.time',
              @model.l.get 'filterDialog.timeLabel'
              z @$timeInput, {
                type: 'number'
                hintText:
                  @model.l.get 'filterDialog.time'
              }

    $title ?= @model.l.get "campground.#{@filter.field}"

    resetButton = {
      text: @model.l.get 'general.reset'
      onclick: =>
        @filter.valueStreams.next RxObservable.of null
        @model.overlay.close()
    }

    z '.z-filter-dialog',
      z @$dialog,
        isVanilla: true
        $title: $title
        $content:
          z '.z-filter-dialog_dialog',
            if @filter.field in ['rigLength', 'crowds', 'roadDifficulty', 'shade', 'safety', 'noise']
              z '.warning',
                @model.l.get 'filterDialog.userInputWarning'
            $content
        cancelButton:
          text: @model.l.get 'general.cancel'
          onclick: =>
            @model.overlay.close()
        resetButton: if @filter.value then resetButton else null
        submitButton:
          text: @model.l.get 'general.done'
          onclick: =>
            @filter.valueStreams.next RxObservable.of filterValue
            @model.overlay.close()
