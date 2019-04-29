z = require 'zorium'
_find = require 'lodash/find'

if window?
  require './index.styl'

Icon = require '../icon'
config = require '../../config'
colors = require '../../colors'

DEFAULT_SIZE = '40px'
PLACEHOLDER_URL = 'data:image/svg+xml;base64,PHN2ZyB3aWR0aD0iMzIiIGhlaWdodD0iMzIiIHhtbG5zPSJodHRwOi8vd3d3LnczLm9yZy8yMDAwL3N2ZyI+CgogPGc+CiAgPHRpdGxlPmJhY2tncm91bmQ8L3RpdGxlPgogIDxyZWN0IGZpbGw9Im5vbmUiIGlkPSJjYW52YXNfYmFja2dyb3VuZCIgaGVpZ2h0PSI0MDIiIHdpZHRoPSI1ODIiIHk9Ii0xIiB4PSItMSIvPgogPC9nPgogPGc+CiAgPHRpdGxlPkxheWVyIDE8L3RpdGxlPgogIDxwYXRoIGlkPSJzdmdfMSIgZD0ibTE2LDhhNCw0IDAgMCAxIDQsNGE0LDQgMCAwIDEgLTQsNGE0LDQgMCAwIDEgLTQsLTRhNCw0IDAgMCAxIDQsLTRtMCwxMGM0LjQyLDAgOCwxLjc5IDgsNGwwLDJsLTE2LDBsMCwtMmMwLC0yLjIxIDMuNTgsLTQgOCwtNHoiIGZpbGw9InJnYmEoMCwgMCwgMCwgMC41KSIvPgogPC9nPgo8L3N2Zz4='

module.exports = class Avatar
  render: ({size, user, groupUser, src, rotation}) ->
    size ?= DEFAULT_SIZE

    if prefix = user?.avatarImage?.prefix
      src or= "#{config.USER_CDN_URL}/#{prefix}.small.jpg"
    # smallUrl is legacy. can probably get rid of in 2019
    src or= user?.avatarImage?.smallUrl or PLACEHOLDER_URL

    playerColors = config.PLAYER_COLORS
    lastChar = user?.id?.substr(user?.id?.length - 1, 1) or 'a'
    avatarColor = playerColors[ \
      Math.ceil (parseInt(lastChar, 16) / 16) * (playerColors.length - 1)
    ]

    # TODO: move to constructor so we don't do this loop every render
    # if groupUser
    #   level = _find(config.XP_LEVEL_REQUIREMENTS, ({xpRequired}) ->
    #     groupUser.xp >= xpRequired
    #   )?.level

    # levelColor = colors["$#{config.XP_LEVEL_COLORS[level]}500"]
    # textShadowColor = colors["$#{config.XP_LEVEL_COLORS[level]}500TextShadow"]

    z '.z-avatar', {
      style:
        width: size
        height: size
        backgroundColor: avatarColor
        # border: if level then "2px solid #{levelColor}" else 'none'
    },
      if src
        z '.image',
          className: if rotation then z.classKebab {"#{rotation}": true}
          style:
            backgroundImage: if user then "url(#{src})"
      # if level
      #   z '.level',  {
      #     style:
      #       backgroundColor: levelColor
      #       color: colors["$#{config.XP_LEVEL_COLORS[level]}500Text"]
      #       textShadow: "0 1px 0 #{textShadowColor}"
      #   },
      #     level
