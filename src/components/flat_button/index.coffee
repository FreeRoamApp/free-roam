z = require 'zorium'
_defaultsDeep = require 'lodash/defaultsDeep'

Button = require '../button'
colors = require '../../colors'

if window?
  require './index.styl'

module.exports = class FlatButton extends Button
  render: (opts) ->
    z '.z-flat-button',
      super _defaultsDeep opts, {
        isFullWidth: true
        colors:
          cText: colors.$tertiary900Text
          # c200: colors.$grey100
          # c500: colors.$white
          # c600: colors.$grey200
          # c700: colors.$grey300
      }
