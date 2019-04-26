z = require 'zorium'
_map = require 'lodash/map'

Avatar = require '../avatar'
CoordinatePicker = require '../coordinate_picker'
Icon = require '../icon'
FlatButton = require '../flat_button'
DateService = require '../../services/date'
colors = require '../../colors'

if window?
  require './index.styl'

module.exports = class UsersNearby
  constructor: ({@model, @router}) ->
    @$locationIcon = new Icon()
    @$changeButton = new FlatButton()

    @state = z.state {
      myLocation: @model.userLocation.getByMe()
      userLocations: @model.userLocation.search {}
      .map (userLocations) ->
        places = _map userLocations?.places, (userLocation) ->
          {
            userLocation
            $avatar: new Avatar()
          }
        {places, total: userLocations?.total}
      me: @model.user.getMe()
    }

  render: =>
    {me, myLocation, userLocations} = @state.getValue()

    console.log userLocations

    z '.z-users-nearby',
      z '.title', @model.l.get 'general.myLocation'
      z '.my-location',
        z '.icon',
          z @$locationIcon,
            icon: 'location'
            color: colors.$secondary500
            isTouchTarget: false
        z '.location',
          @model.placeBase.getName myLocation?.place
        z '.change',
          z @$changeButton,
            text: @model.l.get 'general.change'
            onclick: =>
              @model.overlay.open new CoordinatePicker {
                @model, @router
                onPick: (place) =>
                  console.log 'go', place
                  (if not place.id
                    @model.coordinate.upsert {
                      name: name
                      location: place.location
                    }, {invalidateAll: false}
                  else
                    Promise.resolve null)
                  .then ({id}) =>
                    console.log place.type, id
                    @model.checkIn.upsert {
                      name: place.name
                      sourceType: place.type or 'coordinate'
                      sourceId: place.id or id
                      setUserLocation: true
                    }
                  .then (checkIn) =>
                    @model.overlay.close()
              }

      z '.title',
        @model.l.get 'usersNearby.roamersNearby'
        " (#{userLocations?.total or '...'})"
      z '.users',
        _map userLocations?.places, ({userLocation, $avatar}) =>
          distance = if userLocation.distance is 0 \
                     then '<5'
                     else userLocation.distance
          z '.user',
            z '.avatar',
              z $avatar, {user: userLocation.user}
            z '.info',
              z '.name',
                @model.user.getDisplayName userLocation.user
              z '.location',
                @model.placeBase.getName userLocation?.place
            z '.distance',
              @model.l.get 'usersNearby.distance', {
                replacements: {distance}
              }
