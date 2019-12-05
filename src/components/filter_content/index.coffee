z = require 'zorium'
RxBehaviorSubject = require('rxjs/BehaviorSubject').BehaviorSubject
RxObservable = require('rxjs/Observable').Observable
require 'rxjs/add/observable/combineLatest'
require 'rxjs/add/observable/of'
_map = require 'lodash/map'
_filter = require 'lodash/filter'
_isEmpty = require 'lodash/isEmpty'
_range = require 'lodash/range'
_kebabCase = require 'lodash/kebabCase'
_startCase = require 'lodash/startCase'
_reduce = require 'lodash/reduce'
_zipObject = require 'lodash/zipObject'

Dropdown = require '../dropdown'
Checkbox = require '../checkbox'
CellSelector = require '../cell_selector'
Icon = require '../icon'
PrimaryInput = require '../primary_input'
Rating = require '../rating'
Input = require '../input'
InputRange = require '../input_range'
colors = require '../../colors'
config = require '../../config'

if window?
  require './index.styl'

module.exports = class FilterContent
  constructor: ({@model, @filter, @isGrouped}) ->
    @setup()
    @state = z.state
      filterValue: @filter.valueStreams.switch()

  setup: =>
    if @state
      {filterValue} = @state.getValue() or {}
    else
      filterValue ?= @filter.value

    switch @filter.type
      when 'maxIntCustom', 'minIntCustom'
        @$input = new Input {valueStreams: @filter.valueStreams}
      when 'gtlt'
        @$gt = new Icon()
        @$lt = new Icon()
        @operatorSubject = new RxBehaviorSubject filterValue?.operator
        valueSubject = new RxBehaviorSubject filterValue?.value or ''
        @$input = new Input {value: valueSubject}
        @filter.valueStreams.next RxObservable.combineLatest(
          @operatorSubject, valueSubject, (vals...) -> vals
        ).map ([operator, value]) ->
          if operator or value
            {operator, value}
      when 'maxInt'
        @$inputRange = new InputRange {
          @model
          valueStreams: @filter.valueStreams, minValue: 1, maxValue: 5
        }
      when 'minInt'
        @$inputRange = new InputRange {
          @model
          valueStreams: @filter.valueStreams, minValue: 1, maxValue: 5
        }
      when 'maxIntSeasonal'
        seasonValue = new RxBehaviorSubject @model.time.getCurrentSeason()
        rangeValue = new RxBehaviorSubject filterValue?.value
        @$inputRange = new InputRange {
          @model
          value: rangeValue, minValue: 1, maxValue: 5
        }
        @filter.valueStreams.next RxObservable.combineLatest(
          seasonValue, rangeValue, (vals...) -> vals
        ).map ([season, value]) ->
          if value
            {season, value}
      when 'maxIntDayNight'
        dayNight = new RxBehaviorSubject 'day'
        rangeValue = new RxBehaviorSubject filterValue?.value
        @$inputRange = new InputRange {
          @model
          value: rangeValue, minValue: 1, maxValue: 5
        }
        @filter.valueStreams.next RxObservable.combineLatest(
          dayNight, rangeValue, (vals...) -> vals
        ).map ([dayNight, value]) ->
          if value
            {dayNight, value}
      when 'maxClearance'
        feetValue = new RxBehaviorSubject filterValue?.feet
        @$feetInput = new PrimaryInput {value: feetValue}

        inchesValue = new RxBehaviorSubject filterValue?.inches
        @$inchesInput = new PrimaryInput {value: inchesValue}

        @filter.valueStreams.next RxObservable.combineLatest(
          feetValue
          inchesValue
          (vals...) -> vals
        ).map ([feet, inches]) ->
          if feet or inches
            {feet, inches}
      when 'cellSignal'
        @$cellSelector = new CellSelector {
          @model
          carriers: RxObservable.of ['verizon', 'att', 'tmobile', 'sprint']
          valueStreams: @filter.valueStreams
        }

      when 'iconListBooleanAnd', 'listBooleanAnd', 'listBooleanOr', 'fieldList', 'booleanArraySubTypes'
        list = @filter.items
        @items = _map list, ({key, label}) =>
          valueSubject = new RxBehaviorSubject(
            filterValue?[key]
          )
          {
            valueSubject, label, key
            $icon: if @filter.type is 'iconListBooleanAnd'
              new Icon()
          }

        @filter.valueStreams.next RxObservable.combineLatest(
          _map @items, 'valueSubject'
          (vals...) -> vals
        ).map (vals) ->
          unless _isEmpty _filter(vals)
            _zipObject _map(list, 'key'), vals

      when 'list'
        list = @filter.items

        @checkboxes = _map list, ({key, label}) =>
          valueSubject = new RxBehaviorSubject(
            filterValue?[key]
          )
          $checkbox = new Checkbox {value: valueSubject}
          {valueSubject, $checkbox, label}

        @filter.valueStreams.next RxObservable.combineLatest(
          _map @checkboxes, 'valueSubject'
          (vals...) -> vals
        ).map (vals) ->
          unless _isEmpty _filter(vals)
            _zipObject _map(list, 'key'), vals

      when 'booleanArray'
        @$checkbox = new Checkbox {valueStreams: @filter.valueStreams}

      when 'reviews'
        hasPhotosValueSubject = new RxBehaviorSubject filterValue?.hasPhotos
        @$hasPhotosCheckbox = new Checkbox {value: hasPhotosValueSubject}

        ratingValueSubject = new RxBehaviorSubject filterValue?.rating
        @$rating = new Rating {isInteractive: true, value: ratingValueSubject}

        @filter.valueStreams.next RxObservable.combineLatest(
          hasPhotosValueSubject, ratingValueSubject, (vals...) -> vals
        ).map ([hasPhotos, rating]) ->
          if hasPhotos or rating
            {hasPhotos, rating}

      when 'weather'
        @forecastMetrics = [
          'maxHigh', 'minHigh', 'maxLow', 'minLow', 'rainyDays'
        ]
        @monthDropdownValue = new RxBehaviorSubject(
          if filterValue?.month?
          then filterValue?.month
          else new Date().getMonth()
        )
        @$monthDropdown = new Dropdown {value: @monthDropdownValue}

        # FIXME
        @numberValue = new RxBehaviorSubject filterValue?.number or ''

        metrics = [
          'maxHigh', 'minHigh', 'maxLow', 'minLow', 'rainyDays'
          'tmin', 'tmax', 'precip'
        ]
        @forecastMetrics = ['maxHigh', 'minHigh', 'maxLow', 'minLow', 'rainyDays']
        @weatherMetrics = _reduce metrics, (obj, metric) ->
          savedMetric = filterValue?.metrics?[metric]
          operatorSubject = new RxBehaviorSubject savedMetric?.operator
          valueSubject = new RxBehaviorSubject savedMetric?.value or ''
          obj[metric] = {
            $lt: new Icon(), $gt: new Icon()
            operatorSubject
            valueSubject
            $input: new Input {value: valueSubject}
          }
          obj
        , {}

        @filter.valueStreams.next RxObservable.combineLatest(
          @monthDropdownValue
          @numberValue
          RxObservable.combineLatest(_map(@weatherMetrics, 'operatorSubject')..., (vals...) -> vals)
          RxObservable.combineLatest(_map(@weatherMetrics, 'valueSubject')..., (vals...) -> vals)
          (vals...) -> vals
        ).map ([month, number, operators, values]) =>
          if month and (not _isEmpty(_filter(values)) or month is 'forecast')
            {
              month
              metrics: _reduce values, (obj, value, i) =>
                metric = metrics[i]
                if month is 'forecast' and @forecastMetrics.indexOf(metric) is -1
                  return obj
                else if month isnt 'forecast' and @forecastMetrics.indexOf(metric) isnt -1
                  return obj
                if operators[i] and value or value is '0'
                  obj[metric] = {operator: operators[i], value}
                obj
              , {}
            }
      when 'distanceTo'
        facilityTypes = ['dump', 'groceries', 'water']
        @facilities = _reduce facilityTypes, (obj, facilityType) ->
          valueSubject = new RxBehaviorSubject Boolean filterValue?.facilities?[facilityType]
          obj[facilityType] = {
            valueSubject
            $checkbox: new Checkbox {value: valueSubject}
          }
          obj
        , {}

        @timeValue = new RxBehaviorSubject filterValue?.time or '30'
        @$timeInput = new Input {value: @timeValue}

        @filter.valueStreams.next RxObservable.combineLatest(
          RxObservable.combineLatest(
            _map(@facilities, 'valueSubject')..., (vals...) -> vals
          )
          @timeValue
          (vals...) -> vals
        ).map ([facilities, time]) ->
          facilities = _filter _map facilities, (isChecked, i) ->
            if isChecked
              facilityTypes[i]

          if time and not _isEmpty(_filter(facilities))
            {facilities, time}


  render: =>
    {filterValue} = @state.getValue()

    switch @filter.type
      when 'maxInt', 'maxIntSeasonal', 'minInt', 'maxIntDayNight'
        value = filterValue?.value or filterValue
        $content =
          z '.content',
            if @isGrouped
              z '.title', @filter.title or @filter.name

            unless @isGrouped
              z '.info', @model.l.get "filterSheet.#{@filter.field}Label"
            z '.info', @model.l.get "levelText.#{@filter.field}#{value}"
            z @$inputRange
      when 'maxIntCustom', 'minIntCustom'
        # $title = @model.l.get "campground.#{@filter.key}"
        $content =
          z '.content',
            z '.checkbox-label',
              z '.text', @model.l.get "filterSheet.#{@filter.key}"
              z '.small-input',
                @filter.inputPrefix
                z @$input, {
                  type: 'number'
                  height: '30px'
                  # hintText:
                  #   @model.l.get "campground.#{@filter.key}"
                }
                @filter.inputPostfix
      when 'maxClearance'
        # $title = @model.l.get 'lowClearance.maxClearance'
        $content =
          z '.content',
            z '.label', @model.l.get 'filterSheet.maxClearance'
            z '.fields',
              z @$feetInput, {
                type: 'number'
                hintText:
                  @model.l.get 'filterSheet.feet'
              }
              z @$inchesInput, {
                type: 'number'
                hintText:
                  @model.l.get 'filterSheet.inches'
              }
      when 'iconListBooleanAnd', 'listBooleanAnd', 'listBooleanOr', 'fieldList', 'booleanArraySubTypes'
        $content =
          z '.content',
            if @isGrouped
              z '.title', @filter.title or @filter.name

            z '.tap-items', {
              className: z.classKebab {isFullWidth: @filter.field is 'subType'}
            },
              _map @items, ({valueSubject, label, key, $icon}) =>
                isSelected = valueSubject.getValue()
                z '.tap-item', {
                  className: z.classKebab {
                    isSelected
                    hasIcon: @filter.type is 'iconListBooleanAnd'
                  }
                  onclick: ->
                    valueSubject.next not isSelected
                },
                  if @filter.type is 'iconListBooleanAnd'
                    z '.icon',
                      z $icon,
                        icon: config.FEATURES_ICONS[key] or _kebabCase key
                        isTouchTarget: false
                        size: '20px'
                        color: if isSelected \
                               then colors.$secondary700
                               else colors.$bgText38

                  label or 'fixme'
      when 'list', 'fieldList'
        # $title = @filter?.name
        $content =
          z '.content',
            _map @checkboxes, ({$checkbox, label}) ->
              z 'label.checkbox-label',
                z '.text', label or 'fixme'
                z '.input',
                  z $checkbox
      when 'cellSignal'
        $content =
          z '.content',
            z @$cellSelector, {
              label: @model.l.get 'filterSheet.minSignal'
            }
      when 'reviews'
        $content =
          z '.content',
            z '.info', @model.l.get 'filterSheet.minStarRating'
            z  '.rating',
              z @$rating, {size: '40px', color: colors.$secondaryMain}
            z 'label.checkbox-label',
              z '.text', @model.l.get 'filterSheet.hasPhotos'
              z '.input',
                z @$hasPhotosCheckbox

      when 'gtlt'
        operator = filterValue?.operator
        $content =
          z '.content',
            z '.metric.checkbox-label',
              z '.text', @model.l.get "filterSheet.elevation"
              z '.operators',
                z '.operator', {
                  className: z.classKebab {
                    isSelected: operator is 'gt'
                  }
                  onclick: =>
                    @operatorSubject.next 'gt'
                },
                  z @$gt,
                    icon: 'chevron-right'
                    isTouchTarget: false
                    size: '20px'
                    color: if operator is 'gt' \
                           then colors.$secondaryMainText
                           else colors.$bgText38
                z '.operator', {
                  className: z.classKebab {
                    isSelected: operator is 'lt'
                  }
                  onclick: =>
                    @operatorSubject.next 'lt'
                },
                  z @$lt,
                    icon: 'chevron-left'
                    isTouchTarget: false
                    size: '20px'
                    color: if operator is 'lt' \
                           then colors.$secondaryMainText
                           else colors.$bgText38
              z '.operator-input-wide',
                z @$input, {
                  type: 'number'
                  height: '24px'
                }

      when 'weather'
        metric = filterValue?.metric

        isForecast = filterValue?.month is 'forecast'

        $content =
          z '.content',
            z '.tap-tabs',
              z '.tap-tab', {
                onclick: =>
                  @monthDropdownValue.next new Date().getMonth()
                className:
                  z.classKebab {isSelected: not filterValue or filterValue.month isnt 'forecast'}
              },
                @model.l.get 'filterSheet.monthly'
              z '.tap-tab', {
                onclick: =>
                  @monthDropdownValue.next 'forecast'
                className:
                  z.classKebab {isSelected: isForecast}
              },
                @model.l.get 'filterSheet.weatherForecast'
            if not filterValue or filterValue.month isnt 'forecast'
              z '.month.checkbox-label',
                z '.text', @model.l.get 'general.month'
                z '.input',
                  z @$monthDropdown,
                    options: _map _range(12), (i) =>
                      {value: "#{i}", text: @model.l.get "months.#{i}"}
            _map @weatherMetrics, ({$gt, $lt, $input, operatorSubject}, metric) =>
              if isForecast and @forecastMetrics.indexOf(metric) is -1
                return
              else if not isForecast and @forecastMetrics.indexOf(metric) isnt -1
                return

              operator = operatorSubject.getValue()
              z '.metric.checkbox-label',
                z '.text', @model.l.get "filterSheet.weather.#{metric}"
                z '.operators',
                  z '.operator', {
                    className: z.classKebab {
                      isSelected: operator is 'gt'
                    }
                    onclick: =>
                      operatorSubject.next 'gt'
                  },
                    z $gt,
                      icon: 'chevron-right'
                      isTouchTarget: false
                      size: '20px'
                      color: if operator is 'gt' \
                             then colors.$secondaryMainText
                             else colors.$bgText38
                  z '.operator', {
                    className: z.classKebab {
                      isSelected: operator is 'lt'
                    }
                    onclick: =>
                      operatorSubject.next 'lt'
                  },
                    z $lt,
                      icon: 'chevron-left'
                      isTouchTarget: false
                      size: '20px'
                      color: if operator is 'lt' \
                             then colors.$secondaryMainText
                             else colors.$bgText38
                z '.operator-input',
                  z $input, {
                    type: 'number'
                    height: '24px'
                    # hintText: @model.l.get(
                    #   "filterSheet.weather#{_startCase(metric).replace(/ /g, '')}"
                    # )
            }
      when 'distanceTo'
        $content =
          z '.content',
            [
              _map @facilities, ({$checkbox}, facilityType) =>
                z '.checkbox-label',
                  z '.text', @model.l.get "amenities.#{facilityType}"
                  z '.input',
                    $checkbox
              z 'label.checkbox-label.distance-to-time',
                z '.text',
                  @model.l.get 'filterSheet.timeLabel'
                z '.small-input',
                  z @$timeInput, {
                    type: 'number'
                    height: '30px'
                    hintText:
                      @model.l.get 'filterSheet.time'
                  }
            ]
      when 'booleanArray'
        $content =
          z '.content',
            z 'label.checkbox-label',
              z '.text', @filter.title or @filter.name
              z '.input',
                z @$checkbox

    z '.z-filter-content',
      unless @isGrouped
        z '.title', @filter.title or @filter.name
      z '.content',
        if not @isGrouped and @filter.field in [
          'maxLength', 'crowds', 'roadDifficulty'
          'shade', 'safety', 'noise', 'features'
        ]
          z '.warning',
            @model.l.get 'filterSheet.userInputWarning'
        $content
