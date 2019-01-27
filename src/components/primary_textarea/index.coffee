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
          background: colors.$tertiary100
          c200: colors.$tertiary200Text
          c500: colors.$primary500
          c600: colors.$tertiary600Text
          c700: colors.$tertiary500Text
          ink: colors.$tertiary500Text
      }
