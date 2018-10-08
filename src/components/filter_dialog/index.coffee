z = require 'zorium'
RxBehaviorSubject = require('rxjs/BehaviorSubject').BehaviorSubject
RxObservable = require('rxjs/Observable').Observable
require 'rxjs/add/observable/combineLatest'
_map = require 'lodash/map'
_range = require 'lodash/range'
_startCase = require 'lodash/startCase'

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
  constructor: ({@model, @overlay$, @filter}) ->
    @$dialog = new Dialog {
      onLeave: =>
        @overlay$.next null
    }

    switch @filter.type
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
      when 'weather'
        @monthDropdownValue = new RxBehaviorSubject(
          if @filter.value?.month?
          then @filter.value?.month
          else new Date().getMonth()
        )
        @$monthDropdown = new Dropdown {value: @monthDropdownValue}

        @metricDropdownValue = new RxBehaviorSubject(
          @filter.value?.metric or 'tmin'
        ).do (metric) =>
          switch metric
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

    @state = z.state
      filterValue: filterValue

  render: =>
    {filterValue} = @state.getValue()

    $title = @model.l.get "campground.#{@filter.field}"
    switch @filter.type
      when 'maxInt', 'maxIntSeasonal', 'minInt', 'maxIntDayNight'
        value = filterValue?.value or filterValue
        $content =
          z '.content',
            z @$inputRange, {
              label: @model.l.get "filterDialog.#{@filter.field}Label"
            }
            @model.l.get "levelText.#{@filter.field}#{value}"
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
            z 'label.is-lte',
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
                options: _map _range(12), (i) =>
                  {value: "#{i}", text: @model.l.get "months.#{i}"}
            z '.metric',
              z @$metricDropdown,
                options: [
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
                hintText:
                  @model.l.get "filterDialog.weather#{_startCase(metric)}"
              }

    resetButton = {
      text: @model.l.get 'general.reset'
      onclick: =>
        @filter.valueSubject.next null
        @overlay$.next null
    }

    z '.z-filter-dialog',
      z @$dialog,
        isVanilla: true
        $title: $title
        $content:
          z '.z-filter-dialog_dialog',
            $content
        cancelButton:
          text: @model.l.get 'general.cancel'
          onclick: =>
            @overlay$.next null
        resetButton: if @filter.value then resetButton else null
        submitButton:
          text: @model.l.get 'general.done'
          onclick: =>
            @filter.valueSubject.next filterValue
            @overlay$.next null
