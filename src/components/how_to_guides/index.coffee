z = require 'zorium'
_map = require 'lodash/map'

Icon = require '../icon'
colors = require '../../colors'
config = require '../../config'

if window?
  require './index.styl'

BG_COLORS = [
  colors.$blue50026
  colors.$green50026
  colors.$red50026
]

module.exports = class HowToGuides
  constructor: ({@model, @router}) ->
    me = @model.user.getMe()

    @state = z.state {}

  render: =>
    {} = @state.getValue()

    guides = [
      {
        key: 'guide'
        slug: 'how-to-boondock'
        name: 'How to boondock'
      }
    ]

    z '.z-how-to-guides',
      z '.g-grid',
        z '.g-cols.lt-md-no-padding',
          _map guides, (guide, i) =>
            slug = guide?.slug
            z '.g-col.g-xs-12.g-md-6',
              @router.link z 'a.guide', {
                href: @router.get guide.key, {slug: guide.slug}
              },
                z '.background',
                  # style:
                  #   backgroundImage:
                  #     "url(#{config.CDN_URL}/products/#{slug}-300h.jpg)"
                  z '.gradient'
                z '.overlay', {
                  style:
                      backgroundColor: BG_COLORS[i % BG_COLORS.length]
                },
                  z '.name', guide.name
                  z '.description', guide.description
