z = require 'zorium'

UiCard = require '../ui_card'
SecondaryButton = require '../secondary_button'
TripList = require '../trip_list'

if window?
  require './index.styl'

module.exports = class TripsMine
  constructor: ({@model, @router}) ->
    trips = @model.trip.getAll()

    @$createCustom = new SecondaryButton()
    @$tripList = new TripList {@model, @router, trips}
    @$infoCard = new UiCard()

    @state = z.state {
      hasSeenInfoCard: @model.cookie.get 'hasSeenTripsCard'
    }

  render: =>
    {hasSeenInfoCard} = @state.getValue()

    z '.z-trips-mine',
      if not hasSeenInfoCard
        z '.info-card',
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
