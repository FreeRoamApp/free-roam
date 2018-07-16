z = require 'zorium'
_map = require 'lodash/map'
_range = require 'lodash/range'

colors = require '../../colors'

if window?
  require './index.styl'

DEFAULT_SIZE = 50

module.exports = class Spinner
  render: ({size} = {}) -> #, hasTopMargin} = {}) ->
    size ?= DEFAULT_SIZE
    # hasTopMargin ?= true

    z '.z-spinner', {
      style:
        width: "#{size}px"
        height: "#{size * 0.6}px"
        # marginTop: if hasTopMargin then '16px' else 0
    },
      _map _range(3), ->
        z 'li',
          style:
            border: "#{Math.round(size * 0.06)}px solid #{colors.$primary500}"
