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
        isRaised: false
        isDark: true
        colors:
          c200: colors.$secondary200
          c500: colors.$secondary500
          c600: colors.$secondary600
          c700: colors.$secondary700
          ink: colors.$secondary500Text
      }
