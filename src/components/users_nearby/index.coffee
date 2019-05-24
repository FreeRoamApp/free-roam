z = require 'zorium'
RxReplaySubject = require('rxjs/ReplaySubject').ReplaySubject
RxObservable = require('rxjs/Observable').Observable
require 'rxjs/add/observable/combineLatest'
_filter = require 'lodash/filter'
_map = require 'lodash/map'

Avatar = require '../avatar'
CurrentLocation = require '../current_location'
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

    @$currentLocation = new CurrentLocation {@model, @router}
    @$toggle = new Toggle {
      @model, isSelectedStreams: @isLocationEnabledStreams
    }

    meAndUserLocations = RxObservable.combineLatest(
      @model.user.getMe()
      @model.userLocation.search {}
    )

    @state = z.state {
      isLocationEnabled: @isLocationEnabledStreams.switch()
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


  render: =>
    {me, isLocationEnabled, userLocations} = @state.getValue()

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
                    @$currentLocation.openCoordinatePickerOverlay()
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
            z @$currentLocation

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
