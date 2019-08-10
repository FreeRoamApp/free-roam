z = require 'zorium'
_isEmpty = require 'lodash/isEmpty'
_map = require 'lodash/map'
_startCase = require 'lodash/startCase'

Spinner = require '../spinner'
FormatService = require '../../services/format'
config = require '../../config'

if window?
  require './index.styl'

module.exports = class GroupList
  constructor: ({@model, @router, groups}) ->
    @$spinner = new Spinner()
    @state = z.state
      me: @model.user.getMe()
      groups: groups.map (groups) =>
        _map groups, (group) =>
          {group}

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
          _map groups, ({group}) =>
            group.type ?= 'general'
            route = @model.group.getPath group, 'groupChat', {@router}
            @router.link z 'a.group', {
              href: route
              className: z.classKebab {
                isLight: group?.slug in ['nomadcollab', 'goodvibetribe'] # FIXME: rm hardcode
              }
              style:
                backgroundImage:
                  "url(#{config.CDN_URL}/groups/#{group?.slug}.jpg?1)" # FIXME rm ?1
            },
              z '.name', group.name or @model.l.get 'general.anonymous'
