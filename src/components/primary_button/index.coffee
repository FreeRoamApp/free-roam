z = require 'zorium'
_defaults = require 'lodash/defaults'
Button = require '../button'
colors = require '../../colors'

if window?
  require './index.styl'

module.exports = class PrimaryButton extends Button
  render: (opts) ->
    z '.z-primary-button',
      super _defaults opts, {
        isFullWidth: true
        isRaised: false
        isDark: true
        colors:
          c200: colors.$primaryMain
          c500: colors.$primaryMain
          c600: colors.$primary400
          c700: colors.$primary400
          ink: colors.$primaryMainText
      }
