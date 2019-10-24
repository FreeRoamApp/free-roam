z = require 'zorium'
_defaults = require 'lodash/defaults'

Textarea = require '../textarea'
colors = require '../../colors'

module.exports = class PrimaryTextarea extends Textarea
  render: (opts) =>
    z '.z-primary-textarea',
      super _defaults opts, {
        isFullWidth: true
        isRaised: true
        isFloating: true
        isDark: true
        colors:
          background: colors.$tertiary0
          c200: colors.$tertiary200Text
          c500: colors.$primaryMain
          c600: colors.$tertiary300Text
          c700: colors.$tertiary200Text
          ink: colors.$tertiary200Text
      }
