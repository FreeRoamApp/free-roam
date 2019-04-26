z = require 'zorium'
_map = require 'lodash/map'
_unionBy = require 'lodash/unionBy'
Environment = require '../../services/environment'
RxReplaySubject = require('rxjs/ReplaySubject').ReplaySubject
RxObservable = require('rxjs/Observable').Observable
require 'rxjs/add/observable/combineLatest'
require 'rxjs/add/operator/switchMap'

GroupList = require '../group_list'
UiCard = require '../ui_card'
Icon = require '../icon'
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

    @$unreadInvitesIcon = new Icon()
    @$unreadInvitesChevronIcon = new Icon()

    language = @model.l.getLanguage()

    @state = z.state
      me: me
      language: language
      groups: myGroupsAndPublicGroups

  render: =>
    {me, language, groups} = @state.getValue()

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

    z '.z-groups',
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
        z '.group-list',
          z '.g-grid',
            z 'h2.title', title
          $groupList
