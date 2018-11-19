z = require 'zorium'
_map = require 'lodash/map'
_range = require 'lodash/range'

colors = require '../../colors'

if window?
  require './index.styl'

DEFAULT_SIZE = 50

module.exports = class Spinner
  render: ({size} = {}) ->
    size ?= DEFAULT_SIZE
    # hasTopMargin ?= true

    z '.z-spinner', {
      # style:
      #   width: "#{size}px"
      #   height: "#{size * 0.6}px"
        # marginTop: if hasTopMargin then '16px' else 0
    },
      z '.van',
        z '.chassis'
        z '.wheel-1'
        z '.wheel-2'
        z '.smoke'
      z '.text',
        'Are we there yet?' # FIXME lang
