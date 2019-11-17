z = require 'zorium'
RxBehaviorSubject = require('rxjs/BehaviorSubject').BehaviorSubject
RxObservable = require('rxjs/Observable').Observable
require 'rxjs/add/observable/combineLatest'

ElevationChart = require '../elevation_chart'
Icon = require '../icon'
Spinner = require '../spinner'
colors = require '../../colors'
config = require '../../config'

if window?
  require './index.styl'

module.exports = class EditTripRouteInfoElevation
  constructor: ({@model, routes, routeFocus}) ->
    @$mainGainIcon = new Icon()
    @$mainLostIcon = new Icon()
    @$altGainIcon = new Icon()
    @$altLostIcon = new Icon()
    @$spinner = new Spinner()

    @$elevationChart = new ElevationChart {
      @model
      routes
      routeFocus
      size: @model.window.getSize().map ({width}) ->
        # {width}
        {height: 120}
    }

    @state = z.state {
      routes
    }

  render: =>
    {routes} = @state.getValue()

    mainRoute = routes?[0]
    altRoute = routes?[1]

    z '.z-edit-trip-route-info-elevation',
      if routes
        [
          z '.elevations',
            z '.main',
              z '.icon',
                z @$mainGainIcon,
                  icon: 'arrow-up'
                  isTouchTarget: false
                  color: colors.$secondaryMain
              z '.text',
                "#{mainRoute?.elevationStats.gained} "
                @model.l.get 'abbr.imperial.foot'
              z '.icon',
                z @$mainLostIcon,
                  icon: 'arrow-down'
                  isTouchTarget: false
                  color: colors.$secondaryMain
              z '.text',
                "#{mainRoute?.elevationStats.lost} "
                @model.l.get 'abbr.imperial.foot'

            if altRoute
              z '.alt',
                z '.icon',
                  z @$altGainIcon,
                    icon: 'arrow-up'
                    isTouchTarget: false
                    color: colors.$black54
                z '.text',
                  "#{altRoute?.elevationStats.gained} "
                  @model.l.get 'abbr.imperial.foot'
                z '.icon',
                  z @$altLostIcon,
                    icon: 'arrow-down'
                    isTouchTarget: false
                    color: colors.$black54
                z '.text',
                  "#{altRoute?.elevationStats.lost} "
                  @model.l.get 'abbr.imperial.foot'

          z '.chart',
            @$elevationChart
        ]
      else
        @$spinner
