z = require 'zorium'
_isEmpty = require 'lodash/isEmpty'

UiCard = require '../ui_card'
SecondaryButton = require '../secondary_button'
TripList = require '../trip_list'
config = require '../../config'

if window?
  require './index.styl'

module.exports = class TripsMine
  constructor: ({@model, @router}) ->
    trips = @model.trip.getAll()

    @$videoButton = new SecondaryButton()
    @$getStartedButton = new SecondaryButton()

    @$createCustom = new SecondaryButton()
    @$tripList = new TripList {@model, @router, trips}
    @$infoCard = new UiCard()

    @state = z.state {
      trips: trips
      hasSeenInfoCard: @model.cookie.get 'hasSeenTripsCard'
    }

  render: =>
    {trips, hasSeenInfoCard} = @state.getValue()

    z '.z-trips-mine',
      if @model.experiment.get('tripsOnboard') is 'visible' and _isEmpty trips
        z '.trip-onboard',
          z '.placeholder',
            z '.icon',
              style:
                backgroundImage:
                  "url(#{config.CDN_URL}/empty_state/trip_mine_empty.svg)"
          z '.title', @model.l.get 'tripsMine.onboardTitle'
          z 'ul.features',
            z 'li', @model.l.get 'tripsMine.bullet1'
            z 'li', @model.l.get 'tripsMine.bullet2'
            z 'li', @model.l.get 'tripsMine.bullet3'
          z '.actions',
            z '.action',
              z @$videoButton,
                text: @model.l.get 'tripsMine.videoTutorial'
                isOutline: true
                onclick: =>
                  @model.portal.call 'browser.openWindow', {
                    url: 'https://youtu.be/ZYFOXOlOtXQ'
                    target: '_system'
                  }
            z '.action',
              z @$getStartedButton,
                text: @model.l.get 'general.getStarted'
                isOutline: true
                onclick: =>
                  @router.go 'newTrip', {}, {ignoreHistory: true}

      else
        [
          if not hasSeenInfoCard and @model.experiment.get('tripsOnboard') is 'control'
            z '.info-card',
              z '.g-grid.overflow-visible',
                z @$infoCard, {
                  $title: @model.l.get 'profile.infoCardTitle'
                  $content: @model.l.get 'profile.infoCard'
                  cancel:
                    text: @model.l.get 'general.noThanks'
                    onclick: =>
                      @state.set hasSeenInfoCard: true
                      @model.cookie.set 'hasSeenTripsCard', '1'
                  submit:
                    text: @model.l.get 'profile.watchVideo'
                    onclick: =>
                      @model.portal.call 'browser.openWindow', {
                        url: 'https://youtu.be/ZYFOXOlOtXQ'
                        target: '_system'
                      }
                      @state.set hasSeenInfoCard: true
                      @model.cookie.set 'hasSeenTripsCard', '1'
                }
          z '.create-button',
            z @$createCustom,
              text: @model.l.get 'tripsMine.createCustom'
              onclick: =>
                @router.go 'newTrip', {}, {ignoreHistory: true}
          z @$tripList,
            emptyIcon: 'trip_mine_empty'
            emptyTitle: @model.l.get 'tripsMine.emptyTitle'
            emptyDescription: @model.l.get 'tripsMine.emptyDescription'
        ]
