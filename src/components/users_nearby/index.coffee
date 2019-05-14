z = require 'zorium'
RxReplaySubject = require('rxjs/ReplaySubject').ReplaySubject
RxObservable = require('rxjs/Observable').Observable
require 'rxjs/add/observable/combineLatest'
_filter = require 'lodash/filter'
_map = require 'lodash/map'

Avatar = require '../avatar'
CoordinatePicker = require '../coordinate_picker'
Icon = require '../icon'
FlatButton = require '../flat_button'
Toggle = require '../toggle'
DateService = require '../../services/date'
colors = require '../../colors'

if window?
  require './index.styl'

module.exports = class UsersNearby
  constructor: ({@model, @router, @selectedProfileDialogUser}) ->
    @isLocationEnabledStreams = new RxReplaySubject 1
    @isLocationEnabledStreams.next(
      @model.userSettings.getByMe().map (settings) ->
        settings?.privacy?.location?.everyone
    )

    @$locationIcon = new Icon()
    @$changeButton = new FlatButton()
    @$toggle = new Toggle {
      @model, isSelectedStreams: @isLocationEnabledStreams
    }

    meAndUserLocations = RxObservable.combineLatest(
      @model.user.getMe()
      @model.userLocation.search {}
    )

    @state = z.state {
      isLocationEnabled: @isLocationEnabledStreams.switch()
      myLocation: @model.userLocation.getByMe()
      userLocations: meAndUserLocations
      .map ([me, userLocations]) ->
        places = _filter _map userLocations?.places, (userLocation) ->
          if userLocation.userId is me.id
            return
          {
            userLocation
            $avatar: new Avatar()
          }
        {places, total: userLocations?.total}
      me: @model.user.getMe()
    }

  openCoordinatePicker: =>
    @model.overlay.open new CoordinatePicker {
      @model, @router
      pickButtonText: @model.l.get 'placeInfo.checkIn'
      onPick: (place) =>
        (if not place.id
          @model.coordinate.upsert {
            name: name
            location: place.location
          }, {invalidateAll: false}
        else
          Promise.resolve place)
        .then ({id}) =>
          @model.checkIn.upsert {
            name: place.name
            sourceType: place.type or 'coordinate'
            sourceId: place.id or id
            setUserLocation: true
          }
    }

  render: =>
    {me, isLocationEnabled, myLocation, userLocations} = @state.getValue()

    z '.z-users-nearby',
      z '.g-grid',
        z '.title',
          z '.text', @model.l.get 'general.myLocation'
          z '.toggle',
            z @$toggle, {
              onToggle: (isSelected) =>
                ga? 'send', 'event', 'social', 'enable_location', me?.username
                @model.user.requestLoginIfGuest me
                .then =>
                  if isSelected
                    @openCoordinatePicker()
                  else
                    @model.userLocation.deleteByMe()
                  @model.userSettings.upsert {
                    privacy:
                      location:
                        everyone: Boolean isSelected
                  }
            }
            unless isLocationEnabled
              z '.helper-arrow'
        if isLocationEnabled
          [
            z '.my-location',
              z '.icon',
                z @$locationIcon,
                  icon: 'location'
                  color: colors.$secondary500
                  isTouchTarget: false
              z '.location',
                if myLocation
                  @model.placeBase.getName myLocation.place
                else
                  @model.l.get 'usersNearby.emptyLocation'
              z '.change',
                z @$changeButton,
                  text: @model.l.get 'general.change'
                  onclick: @openCoordinatePicker

            z '.title',
              @model.l.get 'usersNearby.roamersNearby'
              " ("
              if userLocations?.places?
                userLocations?.places.length
              else
                '...'
              ')'
            z '.users',
              unless userLocations?.places?.length
                z '.empty',
                  z '.image'
                  z '.title', @model.l.get 'usersNearby.emptyTitle'
                  z '.description', @model.l.get 'usersNearby.emptyDescription'
              _map userLocations?.places, ({userLocation, $avatar}) =>
                distance = if userLocation.distance is 0 \
                           then '<5'
                           else userLocation.distance
                z '.user', {
                  onclick: =>
                    @selectedProfileDialogUser.next userLocation.user
                },
                  z '.avatar',
                    z $avatar, {
                      user: userLocation.user
                      size: '52px'
                    }
                  z '.info',
                    z '.name',
                      @model.user.getDisplayName userLocation.user
                    z '.location',
                      @model.placeBase.getName userLocation?.place
                  z '.distance',
                    @model.l.get 'usersNearby.distance', {
                      replacements: {distance}
                    }
          ]
        else
          z '.empty',
            z '.image'
            z '.title', @model.l.get 'usersNearby.disabledTitle'
            z '.description', @model.l.get 'usersNearby.disabledDescription'
