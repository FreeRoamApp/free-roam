z = require 'zorium'
_defaults = require 'lodash/defaults'

Button = require '../button'
colors = require '../../colors'

if window?
  require './index.styl'

module.exports = class SecondaryButton extends Button
  render: (opts) ->
    if opts.isInverted
      opts.colors =
        c200: colors.$secondaryMainText
        c500: colors.$secondaryMainText
        c600: colors.$secondaryMainText
        c700: colors.$secondaryMainText
        ink: colors.$secondaryMain
    z '.z-secondary-button',
      super _defaults opts, {
        isFullWidth: true
        isRaised: false
        isDark: true
        colors:
          c200: colors.$secondary200
          c500: colors.$secondaryMain
          c600: colors.$secondary600
          c700: colors.$secondary700
          ink: colors.$secondaryMainText
      }
