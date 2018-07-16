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
        colors:
          cText: colors.$tertiary500Text
          c200: colors.$tertiary500
          c500: colors.$tertiary500
          c600: colors.$tertiary400
          c700: colors.$tertiary400
          ink: colors.$tertiary500Text
      }
