z = require 'zorium'
RxObservable = require('rxjs/Observable').Observable
require 'rxjs/add/observable/of'
_isEmpty = require 'lodash/isEmpty'
_map = require 'lodash/map'

Avatar = require '../avatar'
ButtonMenu = require '../button_menu'
PrimaryButton = require '../primary_button'
Icon = require '../icon'
colors = require '../../colors'
config = require '../../config'

if window?
  require './index.styl'

###
TODO: option to not share past/future trips (maybe mode on the trip itself?)
###

module.exports = class Profile
  constructor: ({@model, @router, user}) ->
    @$avatar = new Avatar()

    @$buttonMenu = new ButtonMenu {@model, @router}

    @state = z.state {
      user
      me: @model.user.getMe()
      pastTrip: user.switchMap (user) =>
        if user
          @model.trip.getByUserIdAndType user.id, 'past'
        else
          RxObservable.of null
      futuretTrip: user.switchMap (user) =>
        if user
          @model.trip.getByUserIdAndType user.id, 'future'
        else
          RxObservable.of null
      $links: user.map (user) ->
        _map user?.links, (link, type) ->
          {
            $icon: new Icon()
            type: type
            link: link
          }
    }

  render: =>
    {user, me, pastTrip, futureTrip, $links} = @state.getValue()

    cacheBust = new Date(pastTrip?.lastUpdateTime).getTime()
    prefix = pastTrip?.imagePrefix or 'trips/default'
    tripImage = @model.image.getSrcByPrefix(
      prefix, {size: 'large', cacheBust}
    )

    isMe = user and user?.id is me?.id
    pastTripPath = if isMe \
          then @router.get 'editTripByType', {type: 'past'}
          else @router.get 'trip', {id: pastTrip?.id}

    z '.z-profile',
      z '.header', {
        style:
          backgroundImage: "url(#{tripImage})"
        onclick: =>
          @router.goPath pastTripPath
      },
        z '.menu', {
          onclick: (e) -> e?.stopPropagation()
        },
          z @$buttonMenu, {color: colors.$header500Icon}
        z '.avatar',
          z @$avatar, {user, size: '80px'}
      z '.info',
        z '.g-grid',
          z '.karma', "#{@model.l.get 'general.karma'}: #{user?.karma or 0}"
          z '.name', @model.user.getDisplayName user
          z '.bio', user?.bio

          unless _isEmpty $links
            z '.links',
              _map $links, ({$icon, link, type}, i) ->
                [
                  unless i is 0
                    z '.divider'
                  z 'a.link', {
                    href: link
                    target: '_system'
                    rel: 'nofollow'
                  },
                    z $icon, {
                      icon: type
                      size: '32px'
                      isTouchTarget: false
                      color: colors.$bgText54
                    }
                ]
          z '.boxes',
            z '.g-cols',
              z '.g-col.g-xs-12.md-12',
                @router.link z 'a.box.reviews', {
                  href: if user?.username \
                      then @router.get 'profileReviews', {username: user?.username}
                      else @router.get 'profileReviewsById', {id: user?.id}
                },
                  z '.title', @model.l.get 'general.reviews'
              z '.g-col.g-xs-12.md-12',
                z '.g-grid',
                  z '.g-cols',
                    z '.g-col.g-xs-6.md-6',
                      @router.link z 'a.box.check-ins', {
                        href: pastTripPath
                      },
                        z '.title',
                          @model.l.get 'general.checkIns'
                          " (#{pastTrip?.checkInIds?.length or 0})"
                    z '.g-col.g-xs-6.md-6',
                      @router.link z 'a.box.planned', {
                        href: if isMe \
                              then @router.get 'editTripByType', {type: 'past'}
                              else @router.get 'trip', {id: pastTrip?.id}
                      },
                        z '.title',
                          @model.l.get 'general.planned'
                          " (#{futureTrip?.checkInIds?.length or 0})"

              z '.g-col.g-xs-12.md-12',
                @router.link z 'a.box.photos', {
                  href: if user?.username \
                      then @router.get 'profileAttachments', {username: user?.username}
                      else @router.get 'profileAttachmentsById', {id: user?.id}
                },
                  z '.title', @model.l.get 'general.photos'
