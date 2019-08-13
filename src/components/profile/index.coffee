z = require 'zorium'
RxObservable = require('rxjs/Observable').Observable
require 'rxjs/add/observable/combineLatest'
require 'rxjs/add/observable/of'
require 'rxjs/add/operator/catch'
RxBehaviorSubject = require('rxjs/BehaviorSubject').BehaviorSubject
_isEmpty = require 'lodash/isEmpty'
_map = require 'lodash/map'
_filter = require 'lodash/filter'

Attachments = require '../attachments'
Avatar = require '../avatar'
Base = require '../base'
ButtonMenu = require '../button_menu'
ButtonBack = require '../button_back'
ProfileActions = require '../profile_actions'
ProfileBoxes = require '../profile_boxes'
ShareMapDialog = require '../share_map_dialog'
Spinner = require '../spinner'
UserList = require '../user_list'
Icon = require '../icon'
DateService = require '../../services/date'
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

    @$editIcon = new Icon()
    @$shareIcon = new Icon()
    @$karmaIcon = new Icon()
    @$editUsernameIcon = new Icon()
    @$homeIcon = new Icon()
    @$occupationIcon = new Icon()
    @$startIcon = new Icon()
    @$reviewsChevronIcon = new Icon()
    @$checkInsChevronIcon = new Icon()
    @$plannedChevronIcon = new Icon()
    @$seeAllAttachmentsChevronIcon = new Icon()
    @$seeAllFriendsChevronIcon = new Icon()

    @$spinner = new Spinner()

    @pastTrip = user.switchMap (user) =>
      if user
        @model.trip.getByUserIdAndType user.id, 'past'
        .catch (err) =>
          err = try
            JSON.parse err.message
          catch
            {}
          if err.status is 401
            RxObservable.of 'private'
          else
            throw err
      else
        RxObservable.of null

    attachments = user.switchMap (user) =>
      unless user
        return RxObservable.of null
      @model.placeAttachment.getAllByUserId user.id

    attachmentsCount = attachments.map (attachments) ->
      attachments?.length or 0

    userAndAttachmentsCount = RxObservable.combineLatest(
      user, attachmentsCount, (vals...) -> vals
    )

    @$attachments = new Attachments {
      @model, @router, attachments, limit: 4
      more: userAndAttachmentsCount.map ([user, count]) =>
        if count > 4 # limit
          path = if user?.username \
                 then @router.get 'profileAttachments', {username: user?.username}
                 else @router.get 'profileAttachmentsById', {id: user?.id}
          {path, count: count - 4}
        else
          false
    }

    friends = user.switchMap (user) =>
      unless user
        return RxObservable.of null
      @model.connection.getAllByUserIdAndType user.id, 'friend'
      .map (connections) ->
        _map connections, (connection) -> connection?.other
    @$friendsList = new UserList {
      @model, @router
      users: friends.map (friends) ->
        friends?.slice 0, 4
    }

    @$shareMapDialog = new ShareMapDialog {
      @model, trip: @pastTrip
      shareInfo: user.map (user) =>
        {
          text: @model.l.get 'trip.shareText'
          url: if user.username \
               then "https://#{config.HOST}/user/#{user.username}"
               else "https://#{config.HOST}/user/id/#{user.id}"
        }
    }

    @$profileActions = new ProfileActions {
      @model, @router, user
    }
    @$profileBoxes = new ProfileBoxes {
      @model, @router, user, @pastTrip
    }

    @state = z.state {
      user
      @pastTrip
      me: @model.user.getMe()
      friendsCount: friends.map (friends) ->
        friends?.length or 0
      attachmentsCount: attachmentsCount
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

  afterMount: (@$$el) =>
    super
    # FIXME: figure out why i can't use take(1) here...
    # returns null for some. probably has to do with the unloading we do in
    # pages/base
    @disposable = @pastTrip.subscribe (pastTrip) =>
      @fadeInWhenLoaded @getCoverUrl(pastTrip)

  beforeUnmount: =>
    @$$el?.scrollTop = 0
    super
    @disposable?.unsubscribe()

  render: =>
    {user, me, attachmentsCount, friendsCount,
      pastTrip, $links} = @state.getValue()

    tripImage = @getCoverUrl pastTrip

    isMe = user and user?.id is me?.id
    pastTripPath = if isMe \
          then @router.get 'tripByType', {type: 'past'}
          else @router.get 'trip', {id: pastTrip?.id}

    z '.z-profile', {
      className: z.classKebab {@isImageLoaded}
      # causes unmount when switching between users' profiles
      # (which we want to happen)
      key: window?.location.pathname
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

      if not user
        z '.info.section.is-loading',
          z @$spinner
      else
        [
          z '.info.section',
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

              if user?.data?.bio
                [
                  z '.bio', user.data.bio
                  z '.divider'
                ]

              z '.bits',
                if user?.data?.home
                  z '.bit',
                    z '.icon',
                      z @$homeIcon,
                        icon: 'home'
                        color: colors.$black54
                        isTouchTarget: false
                    z '.text', user.data.home
                if user?.data?.occupation
                  z '.bit',
                    z '.icon',
                      z @$occupationIcon,
                        icon: 'work'
                        color: colors.$black54
                        isTouchTarget: false
                    z '.text', user.data.occupation
                if user?.data?.startTime
                  z '.bit',
                    z '.icon',
                      z @$startIcon,
                        icon: 'flag'
                        color: colors.$black54
                        isTouchTarget: false
                    z '.text', @model.l.get 'profile.startTime', {
                      replacements:
                        date: DateService.format(
                          new Date user.data.startTime
                          'MMMM yyyy'
                        )
                    }

              unless isMe
                z @$profileActions

              unless _isEmpty $links
                z '.links',
                  _map $links, ({$icon, link, type}, i) =>
                    if link is 'https://'
                      return
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
                          size: '28px'
                          isTouchTarget: false
                          color: colors.$bgText54
                        }
                    ]

              z '.boxes',
                z @$profileBoxes

          z '.section',
            z '.g-grid',
              z '.title',
                @model.l.get 'general.photos'
                z 'span.count', attachmentsCount
              z '.photos',
                z @$attachments
              @router.link z 'a.see-all', {
                href: if user?.username \
                    then @router.get 'profileAttachments', {username: user?.username}
                    else @router.get 'profileAttachmentsById', {id: user?.id}
              },
                z '.text', @model.l.get 'general.seeAll'
                z '.icon',
                  z @$seeAllAttachmentsChevronIcon,
                    icon: 'chevron-right'
                    color: colors.$bgText54
                    isTouchTarget: false

          z '.section',
            z '.g-grid',
              z '.title',
                @model.l.get 'general.friends'
                z 'span.count', friendsCount
              z '.friends',
                z @$friendsList
              @router.link z 'a.see-all', {
                href: if user?.username \
                    then @router.get 'profileFriends', {username: user?.username}
                    else @router.get 'profileFriendsById', {id: user?.id}
              },
                z '.text', @model.l.get 'general.seeAll'
                z '.icon',
                  z @$seeAllFriendsChevronIcon,
                    icon: 'chevron-right'
                    color: colors.$bgText54
                    isTouchTarget: false
        ]
