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
          z '.g-grid',
            @model.l.get 'groupList.empty'
      else if not groups
        @$spinner
      else if groups
        z '.groups',
          z '.g-grid',
            z '.g-cols',
              _map groups, ({group}) =>
                # FIXME: rm hardcode (midwest vanlife gathering)
                # automate the images
                key = if group?.slug is 'mvg' then 'mvg' else 'freeroam'

                group.type ?= 'general'
                route = @model.group.getPath group, 'groupChat', {@router}
                z '.g-col.g-xs-12.g-md-6',
                  @router.link z 'a.group', {
                    href: route
                  },
                    z '.image',
                      style:
                        backgroundImage:
                          "url(#{config.CDN_URL}/groups/#{key}.png)"
                    z '.content',
                      z '.name', group.name or @model.l.get 'general.anonymous'
                      z '.count',
                        # @model.l.get "groupList.type#{_startCase(group.type)}"
                        @model.l.get 'general.chat'
                        # [
                        #   z 'span.middot',
                        #     innerHTML: ' &middot; '
                        #   "#{FormatService.number group.userCount} "
                        #   @model.l.get 'general.members'
                        # ]
