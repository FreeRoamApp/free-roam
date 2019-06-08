z = require 'zorium'
RxObservable = require('rxjs/Observable').Observable
require 'rxjs/add/observable/of'

UiCard = require '../ui_card'
colors = require '../../colors'
config = require '../../config'

if window?
  require './index.styl'

module.exports = class ProfileActions
  constructor: ({@model, @router, user, @pastTrip}) ->
    @$infoCard = new UiCard()

    @state = z.state {
      me: @model.user.getMe()
      user
      hasSeenProfileCard: @model.cookie.get 'hasSeenProfileCard'
      pastTrip: @pastTrip.map (pastTrip) -> pastTrip or false
      reviewCount: user.switchMap (user) =>
        @model.placeReview.getCountByUserId user.id
      futureTrip: user.switchMap (user) =>
        if user
          @model.trip.getByUserIdAndType user.id, 'future'
          .catch (err) =>
            err = try
              JSON.parse err.message
            catch
              {}
            if err.status is 401
              RxObservable.of false
            else
              throw err
        else
          RxObservable.of null
    }

  render: =>
    {me, user, hasSeenProfileCard, pastTrip, futureTrip,
      reviewCount} = @state.getValue()

    isMe = user and user?.id is me?.id
    pastTripPath = if isMe \
          then @router.get 'tripByType', {type: 'past'}
          else @router.get 'trip', {id: pastTrip?.id}

    z '.z-profile-boxes',
      if isMe and not hasSeenProfileCard
        z '.info-card',
          z @$infoCard, {
            $title: @model.l.get 'profile.infoCardTitle'
            $content: @model.l.get 'profile.infoCard'
            cancel:
              text: @model.l.get 'general.noThanks'
              onclick: =>
                @state.set hasSeenProfileCard: true
                @model.cookie.set 'hasSeenProfileCard', '1'
            submit:
              text: @model.l.get 'profile.watchVideo'
              onclick: =>
                @model.portal.call 'browser.openWindow', {
                  url: 'https://youtu.be/Fsw0VbgfB2c'
                  target: '_system'
                }
                @state.set hasSeenProfileCard: true
                @model.cookie.set 'hasSeenProfileCard', '1'
          }

      z '.g-grid',
        z '.g-cols',
          z '.g-col.g-xs-12.md-12',
            @router.link z 'a.box.reviews', {
              href: if user?.username \
                  then @router.get 'profileReviews', {username: user?.username}
                  else @router.get 'profileReviewsById', {id: user?.id}
            },
              z '.info',
                z '.count', reviewCount or 0
                z '.title', @model.l.get 'general.reviews'
              z '.chevron',
                z @$reviewsChevronIcon,
                  icon: 'chevron-right'
                  isTouchTarget: false
                  color: colors.$white
          z '.g-col.g-xs-12.md-12',
            z '.g-grid',
              z '.g-cols',
                z '.g-col.g-xs-6.md-6',
                  if pastTrip is 'private' and not isMe # false = private
                    z '.box.check-ins',
                      z '.info',
                        z '.count', @model.l.get 'general.private'
                        z '.title', @model.l.get 'general.checkIns'
                  else
                    @router.link z 'a.box.check-ins', {
                      href: pastTripPath
                    },
                      z '.info',
                        z '.count', pastTrip?.checkInIds?.length or 0
                        z '.title',
                          @model.l.get 'general.checkIns'
                      z '.chevron',
                        z @$checkInsChevronIcon,
                          icon: 'chevron-right'
                          isTouchTarget: false
                          color: colors.$white
                z '.g-col.g-xs-6.md-6',
                  if futureTrip is 'private' and not isMe # false = private
                    z '.box.planned',
                      z '.info',
                        z '.count', @model.l.get 'general.private'
                        z '.title', @model.l.get 'general.planned'
                  else
                    @router.link z 'a.box.planned', {
                      href: if isMe \
                            then @router.get 'tripByType', {type: 'future'}
                            else @router.get 'trip', {id: futureTrip?.id}
                    },
                      z '.info',
                        z '.count', futureTrip?.checkInIds?.length or 0
                        z '.title',
                          @model.l.get 'profile.plannedPlaces'
                      z '.chevron',
                        z @$plannedChevronIcon,
                          icon: 'chevron-right'
                          isTouchTarget: false
                          color: colors.$white
