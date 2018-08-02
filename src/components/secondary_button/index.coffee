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
          c200: colors.$secondary500
          c500: colors.$secondary500
          c600: colors.$secondary400
          c700: colors.$secondary400
          ink: colors.$secondary500Text
      }
