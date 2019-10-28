z = require 'zorium'
_isEmpty = require 'lodash/isEmpty'
_map = require 'lodash/map'
_startCase = require 'lodash/startCase'

Base = require '../base'
Spinner = require '../spinner'
FlatButton = require '../flat_button'
FormatService = require '../../services/format'
config = require '../../config'

if window?
  require './index.styl'

module.exports = class GroupList extends Base
  constructor: ({@model, @router, groups}) ->
    @$spinner = new Spinner()
    @state = z.state
      me: @model.user.getMe()
      groups: groups.map (groups) =>
        _map groups, (group) =>
          {
            group
            $forumButton: new FlatButton()
            $chatButton: new FlatButton()
          }

  render: =>
    {groups, me} = @state.getValue()

    z '.z-group-list',
      if groups and _isEmpty groups
        z '.no-groups',
          @model.l.get 'groupList.empty'
      else if not groups
        @$spinner
      else if groups
        z '.groups', {
          ontouchstart: (e) ->
            e.stopPropagation()
        },
          _map groups, ({group, $forumButton, $chatButton}) =>
            group.type ?= 'general'
            url = "#{config.CDN_URL}/groups/#{group?.slug}.jpg"
            z '.group',
              z '.image', {
                className: @getImageLoadHashByUrl url
                onclick: =>
                  @model.group.goPath group, 'groupChat', {@router}
                style:
                  backgroundImage:
                    "url(#{url})"
              },
                z '.name', group.name or @model.l.get 'general.anonymous'
              z '.actions',
                z '.action',
                  z $forumButton,
                    text: @model.l.get 'general.forum'
                    onclick: =>
                      @model.group.goPath group, 'groupForum', {@router}
                z '.action.chat',
                  z $chatButton,
                    text: @model.l.get 'general.chat'
                    onclick: =>
                      @model.group.goPath group, 'groupChat', {@router}
