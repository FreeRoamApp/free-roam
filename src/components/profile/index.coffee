z = require 'zorium'
RxObservable = require('rxjs/Observable').Observable
require 'rxjs/add/observable/of'
require 'rxjs/add/operator/catch'
_isEmpty = require 'lodash/isEmpty'
_map = require 'lodash/map'
_filter = require 'lodash/filter'

Avatar = require '../avatar'
Base = require '../base'
ButtonMenu = require '../button_menu'
ButtonBack = require '../button_back'
PrimaryButton = require '../primary_button'
ShareMapDialog = require '../share_map_dialog'
UiCard = require '../ui_card'
Icon = require '../icon'
colors = require '../../colors'
config = require '../../config'

if window?
  require './index.styl'

###
TODO: separate out into profileInfo, profilePhotos and profileFriends
###

module.exports = class Profile extends Base
  constructor: ({@model, @router, user}) ->
    @$avatar = new Avatar()

    @$buttonMenu = new ButtonMenu {@model, @router}
    @$buttonBack = new ButtonBack {@model, @router}

    @$messageButton = new PrimaryButton()
    @$friendButton = new PrimaryButton()

    @$editIcon = new Icon()
    @$shareIcon = new Icon()
    @$karmaIcon = new Icon()
    @$editUsernameIcon = new Icon()
    @$reviewsChevronIcon = new Icon()
    @$checkInsChevronIcon = new Icon()
    @$plannedChevronIcon = new Icon()

    @pastTrip = user.switchMap (user) =>
      if user
        @model.trip.getByUserIdAndType user.id, 'past'
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

    @$shareMapDialog = new ShareMapDialog {
      @model, trip: @pastTrip
      shareInfo: user.map (user) =>
        {
          text: @model.l.get 'trip.shareText'
          url: if user.username \
               then "#{config.HOST}/user/#{user.username}"
               else "#{config.HOST}/user/id/#{user.id}"
        }
    }

    @$infoCard = new UiCard()

    @state = z.state {
      user
      me: @model.user.getMe()
      isMessageLoading: false
      isFriendLoading: false
      hasSeenProfileCard: @model.cookie.get 'hasSeenProfileCard'
      pastTrip: @pastTrip.map (pastTrip) -> pastTrip or false
      reviewCount: user.switchMap (user) =>
        @model.placeReview.getCountByUserId user.id
      isFriends: user.switchMap (user) =>
        if user
          @model.connection.isConnectedByUserIdAndType(
            user.id, 'friend'
          )
        else
          RxObservable.of false
      isFriendRequested: user.switchMap (user) =>
        if user
          @model.connection.isConnectedByUserIdAndType(
            user.id, 'friendRequestSent'
          )
        else
          RxObservable.of false
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
      $links: user.map (user) ->
        _filter _map user?.links, (link, type) ->
          if link
            {
              $icon: new Icon()
              type: type
              link: link
            }
    }

  getCoverUrl: (pastTrip) ->
    cacheBust = new Date(pastTrip?.lastUpdateTime).getTime()
    prefix = pastTrip?.imagePrefix or 'trips/default'
    tripImage = @model.image.getSrcByPrefix(
      prefix, {size: 'large', cacheBust}
    )

  afterMount: =>
    super
    # FIXME: figure out why i can't use take(1) here...
    # returns null for some. probably has to do with the unloading we do in
    # pages/base
    @disposable = @pastTrip.subscribe (pastTrip) =>
      @fadeInWhenLoaded @getCoverUrl(pastTrip)

  beforeUnmount: =>
    super
    @disposable?.unsubscribe()

  render: =>
    {user, me, pastTrip, futureTrip, isMessageLoading, isFriendLoading,
      isFriends, isFriendRequested, reviewCount,
      hasSeenProfileCard, $links} = @state.getValue()

    tripImage = @getCoverUrl pastTrip

    isMe = user and user?.id is me?.id
    pastTripPath = if isMe \
          then @router.get 'tripByType', {type: 'past'}
          else @router.get 'trip', {id: pastTrip?.id}

    z '.z-profile', {
      className: z.classKebab {@isImageLoaded}
    },
      z '.header',
        z '.cover', {
          style:
            backgroundImage:
              if pastTrip? then "url(#{tripImage})"
          onclick: =>
            @router.goPath pastTripPath
        }
        z '.menu', {
          onclick: (e) -> e?.stopPropagation()
        },
          if isMe
            z @$buttonMenu, {color: colors.$bgText87}
          else
            z @$buttonBack, {color: colors.$bgText87}
        if isMe
          z '.buttons', {
            onclick: (e) -> e?.stopPropagation()
          },
            z '.edit',
              z @$editIcon,
                icon: 'edit'
                color: colors.$bgText87
                onclick: =>
                  @router.go 'editProfile'
            z '.share',
              z @$shareIcon,
                icon: 'share'
                color: colors.$bgText87
                onclick: =>
                  ga? 'send', 'event', 'profile', 'share', 'click'
                  @model.overlay.open @$shareMapDialog
        z '.avatar', {
          onclick: (e) =>
            e?.stopPropagation()
            if isMe
              @router.go 'editProfile'
        },
          z @$avatar, {user, size: '80px', hasBorder: false}
      z '.info',
        z '.g-grid',
          z '.karma',
            z '.icon',
              z @$karmaIcon,
                icon: 'karma'
                isTouchTarget: false
                color: colors.$secondary500
                size: '18px'
            user?.karma or 0
          z '.name',
            @model.user.getDisplayName user
            if isMe and not user.username
              z '.icon',
                z @$editUsernameIcon,
                  icon: 'edit'
                  isTouchTarget: false
                  onclick: =>
                    @router.go 'editProfile'
          z '.bio', user?.bio

          unless isMe
            z '.actions',
              z '.action',
                z @$messageButton,
                  text: if isMessageLoading \
                        then @model.l.get 'general.loading'
                        else @model.l.get 'general.messageVerb'
                  onclick: =>
                    @state.set isMessageLoading: true
                    @model.conversation.create {
                      userIds: [user.id]
                    }
                    .then (conversation) =>
                      @state.set isMessageLoading: false
                      @router.go 'conversation', {id: conversation.id}
              z '.action',
                z @$friendButton,
                  isOutline: true
                  text: if isFriends \
                        then @model.l.get 'profile.unfriend'
                        else if isFriendRequested
                        then @model.l.get 'profile.sentFriendRequest'
                        else if isFriendLoading
                        then @model.l.get 'general.loading'
                        else @model.l.get 'profile.sendFriendRequest'
                  onclick: =>
                    @model.user.requestLoginIfGuest me
                    .then =>
                      if isFriends
                        isConfirmed = confirm @model.l.get 'profile.confirmUnfriend'
                        fn = =>
                          @model.connection.deleteByUserIdAndType(
                            user.id, 'friend'
                          )
                      else
                        isConfirmed = true
                        fn = =>
                          @model.connection.upsertByUserIdAndType(
                            user.id, 'friendRequestSent'
                          )
                      if isConfirmed and not isFriendRequested
                        @state.set isFriendLoading: true
                        fn()
                        .then =>
                          @state.set isFriendLoading: false

          unless _isEmpty $links
            z '.links',
              _map $links, ({$icon, link, type}, i) =>
                [
                  unless i is 0
                    z '.divider'
                  @router.link z 'a.link', {
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
                        if pastTrip is false # false = private
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
                        if futureTrip is false # false = private
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
                                @model.l.get 'general.planned'
                            z '.chevron',
                              z @$plannedChevronIcon,
                                icon: 'chevron-right'
                                isTouchTarget: false
                                color: colors.$white

                z '.g-col.g-xs-12.md-12',
                  @router.link z 'a.box.photos', {
                    href: if user?.username \
                        then @router.get 'profileAttachments', {username: user?.username}
                        else @router.get 'profileAttachmentsById', {id: user?.id}
                  },
                    z '.title', @model.l.get 'general.photos'
