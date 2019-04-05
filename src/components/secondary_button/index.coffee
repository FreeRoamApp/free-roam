z = require 'zorium'
_defaults = require 'lodash/defaults'

Button = require '../button'
colors = require '../../colors'

if window?
  require './index.styl'

module.exports = class SecondaryButton extends Button
  render: (opts) ->
    z '.z-secondary-button',
      super _defaults opts, {
        isFullWidth: true
        isRaised: true
        isDark: true
        colors:
          c200: colors.$quaternary200
          c500: colors.$quaternary500
          c600: colors.$quaternary600
          c700: colors.$quaternary700
          ink: colors.$quaternary500Text
      }
