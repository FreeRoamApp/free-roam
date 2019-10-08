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
      pastTrip: @pastTrip.map (pastTrip) -> pastTrip or false
      reviewCount: user.switchMap (user) =>
        unless user
          return RxObservable.of null
        @model.placeReview.getCountByUserId user.id
    }

  render: =>
    {me, user, pastTrip,
      reviewCount} = @state.getValue()

    isMe = user and user?.id is me?.id
    pastTripPath = @router.get 'trip', {id: pastTrip?.id}

    z '.z-profile-boxes',
      z '.g-grid',
        z '.g-cols',
          z '.g-col.g-xs-12.g-md-12',
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
          # z '.g-col.g-xs-12.g-md-12',
          #   z '.g-grid',
          #     z '.g-cols',
          #       z '.g-col.g-xs-6.g-md-6',
          #         if pastTrip is 'private' and not isMe # false = private
          #           z '.box.check-ins',
          #             z '.info',
          #               z '.count', @model.l.get 'general.private'
          #               z '.title', @model.l.get 'general.checkIns'
          #         else
          #           @router.link z 'a.box.check-ins', {
          #             href: pastTripPath
          #           },
          #             z '.info',
          #               z '.count', pastTrip?.checkInIds?.length or 0
          #               z '.title',
          #                 @model.l.get 'general.checkIns'
          #             z '.chevron',
          #               z @$checkInsChevronIcon,
          #                 icon: 'chevron-right'
          #                 isTouchTarget: false
          #                 color: colors.$white
          #       z '.g-col.g-xs-6.g-md-6',
          #         if futureTrip is 'private' and not isMe # false = private
          #           z '.box.planned',
          #             z '.info',
          #               z '.count', @model.l.get 'general.private'
          #               z '.title', @model.l.get 'general.planned'
          #         else
          #           @router.link z 'a.box.planned', {
          #             href: if isMe \
          #                   then @router.get 'tripByType', {type: 'future'}
          #                   else @router.get 'trip', {id: futureTrip?.id}
          #           },
          #             z '.info',
          #               z '.count', futureTrip?.checkInIds?.length or 0
          #               z '.title',
          #                 @model.l.get 'profile.plannedPlaces'
          #             z '.chevron',
          #               z @$plannedChevronIcon,
          #                 icon: 'chevron-right'
          #                 isTouchTarget: false
          #                 color: colors.$white
