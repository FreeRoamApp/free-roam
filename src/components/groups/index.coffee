z = require 'zorium'
_defaults = require 'lodash/defaults'
_map = require 'lodash/map'
_take = require 'lodash/take'
_unionBy = require 'lodash/unionBy'
Environment = require '../../services/environment'
RxReplaySubject = require('rxjs/ReplaySubject').ReplaySubject
RxObservable = require('rxjs/Observable').Observable
require 'rxjs/add/observable/combineLatest'
require 'rxjs/add/operator/switchMap'
require 'rxjs/add/operator/startWith'

GroupList = require '../group_list'
EventList = require '../event_list'
Icon = require '../icon'
DateService = require '../../services/date'
colors = require '../../colors'
config = require '../../config'

if window?
  require './index.styl'

module.exports = class Groups
  constructor: ({@model, @router}) ->
    me = @model.user.getMe()
    myGroups = me.switchMap (me) =>
      @model.group.getAllByUserId me.id
    publicGroups = @model.l.getLanguage().switchMap (language) =>
      @model.group.getAll({filter: 'public', language})
    myGroupsAndPublicGroups = RxObservable.combineLatest(
      myGroups
      publicGroups
      (myGroups, publicGroups) ->
        _unionBy (myGroups or []), publicGroups, 'id'
    )
    @$myGroupList = new GroupList {
      @model
      @router
      groups: myGroupsAndPublicGroups
    }
    # @$suggestedGroupsList = new GroupList {
    #   @model
    #   @router
    #   groups: @model.group.getAll({filter: 'suggested'})
    # }

    @$eventList = new EventList {
      @model
      @router
      events: @model.event.getAll()
      .startWith([{}, {}, {}]) # 3 placeholder for initial load less jank
      .map (events) ->
        _take events, 3
    }

    # @$unreadInvitesIcon = new Icon()
    # @$unreadInvitesChevronIcon = new Icon()
    @$seeAllEventsIcon = new Icon()

    language = @model.l.getLanguage()

    @state = z.state
      me: me
      language: language
      groups: myGroupsAndPublicGroups
      events: @model.event.getAll().map (events) ->
        _map events, (event) ->
          _defaults {
            startTime: DateService.format new Date(event.startTime), 'MMM D'
            endTime: DateService.format new Date(event.endTime), 'MMM D'
          }, event

  render: =>
    {me, language, groups, events} = @state.getValue()

    groupTypes = [
      {
        title: @model.l.get 'groups.myGroupList'
        $groupList: @$myGroupList
      }
      # {
      #   title: @model.l.get 'groups.suggestedGroupList'
      #   $groupList: @$suggestedGroupsList
      # }
    ]

    # unreadGroupInvites = me?.data.unreadGroupInvites
    # inviteStr = if unreadGroupInvites is 1 then 'invite' else 'invites'

    z '.z-groups', [
      # if unreadGroupInvites
      #   @router.link z 'a.unread-invites', {
      #     href: @router.get 'groupInvites'
      #   },
      #     z '.icon',
      #       z @$unreadInvitesIcon,
      #         icon: 'notifications'
      #         isTouchTarget: false
      #         color: colors.$tertiary500
      #     z '.text', "You have #{unreadGroupInvites} new group #{inviteStr}"
      #     z '.chevron',
      #       z @$unreadInvitesChevronIcon,
      #         icon: 'chevron-right'
      #         isTouchTarget: false
      #         color: colors.$primary500
      _map groupTypes, ({title, $groupList}) ->
        [
          z '.title',
            z '.g-grid', title
          z '.group-list',
            z '.g-grid', $groupList
        ]

      z '.title',
        z '.g-grid', @model.l.get 'general.meetups'
      z '.events',
        @$eventList

        @router.link z 'a.see-all', {
          href: @router.get 'events'
        },
          z '.g-grid',
            z '.text', @model.l.get 'general.seeAll'
            z '.icon',
              z @$seeAllEventsIcon,
                icon: 'chevron-right'
                color: colors.$bgText54
                isTouchTarget: false
    ]
