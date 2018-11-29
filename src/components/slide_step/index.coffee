z = require 'zorium'
_startCase = require 'lodash/startCase'

colors = require '../../colors'

if window?
  require './index.styl'

module.exports = class SlideStep
  render: ({$content, $image, colorName}) ->
    z '.z-slide-step', {
      className: z.classKebab {"is#{_startCase(colorName)}": true}
    },
      z '.screenshot-block',
        $image
      z '.info-block',
        $content
