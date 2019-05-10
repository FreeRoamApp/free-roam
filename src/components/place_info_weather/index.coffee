z = require 'zorium'
_map = require 'lodash/map'
_chunk = require 'lodash/chunk'
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
        _map days, (day) ->
          date = new Date(day.time * 1000)
          _defaults {
            dow: date.getDay()
            date: "#{date.getMonth() + 1}/#{date.getDate()}"
            $rainIcon: new Icon()
            $windIcon: new Icon()
            $temperatureIcon: new Icon()
          }, day
      currentTab: 'avg'

  render: =>
    {place, forecastDaily, currentTab} = @state.getValue()

    tabs = ['avg', 'forecast']

    forecastDayChunks = _chunk forecastDaily, 4

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
        z '.forecast', [
          _map forecastDayChunks, (days, chunkI) =>
            z '.row',
              _map days, (day, i) =>
                z '.day',
                  z '.day-of-week',
                    if chunkI is 0 and i is 0
                      @model.l.get 'general.today'
                    else if chunkI is 0 and i is 1
                      @model.l.get 'general.tomorrow'
                    else
                      @model.l.get "daysAbbr.#{day.dow}"
                  z '.date', day.date
                  z 'img.icon',
                    src: "#{config.CDN_URL}/weather/#{day.icon}.svg"
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
                        icon: 'wind'
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
        ]
