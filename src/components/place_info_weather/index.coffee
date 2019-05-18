z = require 'zorium'
_map = require 'lodash/map'
_filter = require 'lodash/filter'
_chunk = require 'lodash/chunk'
_startCase = require 'lodash/startCase'
_defaults = require 'lodash/defaults'

Icon = require '../icon'
FormatService = require '../../services/format'
colors = require '../../colors'
config = require '../../config'

if window?
  require './index.styl'

module.exports = class PlaceInfoWeather
  constructor: ({@model, @router, place}) ->
    @state = z.state
      place: place
      forecastDaily: place.map (place) ->
        days = place?.forecast?.daily
        today = new Date()
        todayFullDateStr =
          "#{today.getYear()}/#{today.getMonth() + 1}/#{today.getDate()}"
        _filter _map days, (day) ->
          date = new Date(day.time * 1000)
          dateStr = "#{date.getMonth() + 1}/#{date.getDate()}"
          if "#{date.getYear()}/#{dateStr}" < todayFullDateStr
            return
          _defaults {
            dow: date.getDay()
            date: dateStr
            $weatherIcon: new Icon()
            $rainIcon: new Icon()
            $windIcon: new Icon()
            $temperatureIcon: new Icon()
          }, day
      currentTab: 'avg'

  render: =>
    {place, forecastDaily, currentTab} = @state.getValue()

    tabs = ['avg', 'forecast']


    z '.z-place-info-weather',
      z '.title', @model.l.get 'placeInfo.weather'

      z '.tabs',
        _map tabs, (tab) =>
          z '.tab', {
            className: z.classKebab {isSelected: currentTab is tab}
            onclick: =>
              @state.set {currentTab: tab}
          },
            @model.l.get "placeInfoWeather.#{tab}"
      if currentTab is 'avg'
        z 'img.graph', {
          src:
            "#{config.USER_CDN_URL}/weather/#{place?.type}_#{place?.id}.svg?2"
        }
      else
        z '.forecast',
          z '.days', {
            ontouchstart: (e) ->
              e.stopPropagation()
          },
            _map forecastDaily, (day, i) =>
              icon = day.icon.replace 'night', 'day'
              iconColor = "$weather#{_startCase(icon).replace(/ /g, '')}"
              z '.day',
                z '.day-of-week',
                  if i is 0
                    @model.l.get 'general.today'
                  else if i is 1
                    @model.l.get 'general.tomorrow'
                  else
                    @model.l.get "daysAbbr.#{day.dow}"
                z '.date', day.date
                z '.icon',
                  z day.$weatherIcon,
                    icon: "weather-#{icon}"
                    color: colors[iconColor] or
                            colors.$bgText87
                    isTouchTarget: false
                    size: '48px'
                z '.high-low',
                  z '.icon',
                    z day.$temperatureIcon,
                      icon: 'thermometer'
                      size: '16px'
                      isTouchTarget: false
                  z '.high', Math.round(day.temperatureHigh) + '°'
                  z '.divider', '|'
                  z '.low', Math.round(day.temperatureLow) + '°F'
                z '.rain',
                  z '.icon',
                    z day.$rainIcon,
                      icon: 'water'
                      size: '16px'
                      isTouchTarget: false
                  z '.percent', FormatService.percentage day.precipProbability
                  z '.divider', '|'
                  z '.amount', "#{day.precipTotal}\""
                z '.wind',
                  z '.icon',
                    z day.$windIcon,
                      icon: 'weather-wind'
                      size: '16px'
                      isTouchTarget: false
                  z '.info',
                    z '.speed',
                      z 'span.type',
                        @model.l.get 'placeInfoWeather.windSpeed'
                        ': '
                      Math.round day.windSpeed
                      z 'span.caption', 'MPH'
                    z '.gust',
                      z 'span.type',
                        @model.l.get 'placeInfoWeather.windGust'
                        ': '
                      Math.round day.windGust
                      z 'span.caption', 'MPH'

          @router.link z 'a.attribution', {
            href: 'https://darksky.net'
            target: '_system'
          },
            @model.l.get 'placeInfoWeather.attribution'
