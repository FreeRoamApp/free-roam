z = require 'zorium'
_startCase = require 'lodash/startCase'

CurrentLocation = require '../current_location'
Icon = require '../icon'
Rating = require '../rating'
colors = require '../../colors'
config = require '../../config'

if window?
  require './index.styl'

###
FIXME FIXME: current location can't be updated if location sharing is off. it should be updatable still.... just not searchable
###

module.exports = class Dashboard
  constructor: ({@model, @router}) ->
    me = @model.user.getMe()

    @$currentLocation = new CurrentLocation {@model, @router}

    @$rating = new Rating {
      isInteractive: true
    }

    @state = z.state {
      myLocation: @model.userLocation.getByMe()
    }

  render: =>
    {myLocation} = @state.getValue()

    weatherType = _startCase('clear').replace(/ /g, '')

    console.log myLocation
    console.log weatherType
    todayForecast = myLocation?.place?.forecast?.daily?[0]
    console.log todayForecast


    z '.z-dashboard',
      z '.g-grid',
        z '.current-location',
          z @$currentLocation

          z '.rating',
            z @$rating, {size: '32px'}
            z '.text', @model.l.get 'dashboard.rate'

        z '.card',
          z '.title', @model.l.get 'dashboard.weather'
          z '.weather', {
            className: z.classKebab {"is#{weatherType}": true}
          },
            z '.icon'
            z '.info',
              z '.date', @model.l.get 'general.today'
              z '.text', 'Sunny, 41' # FIXME
              z '.high-low'
              z '.rain'
              z '.wind'

        z '.card', 'nearby'
