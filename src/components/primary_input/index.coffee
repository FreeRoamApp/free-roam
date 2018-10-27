z = require 'zorium'
_defaults = require 'lodash/defaults'

Icon = require '../icon'
Input = require '../input'
colors = require '../../colors'


if window?
  require './index.styl'

module.exports = class PrimaryInput extends Input
  constructor: ->
    @state = z.state isPasswordVisible: false
    @$eyeIcon = new Icon()
    super

  render: (opts) =>
    {isPasswordVisible} = @state.getValue()

    optType = opts.type

    opts.type = if isPasswordVisible then 'text' else opts.type

    isFullWidth = opts.isFullWidth

    z '.z-primary-input', {
      className: z.classKebab {isFullWidth}
    },
      super _defaults opts, {
        isRaised: true
        isFloating: true
        isDark: true
        colors:
          background: colors.$tertiary100
          c200: colors.$tertiary200Text
          c500: colors.$bgText
          c600: colors.$tertiary600Text
          c700: colors.$tertiary500Text
          ink: colors.$tertiary500Text
      }
      if optType is 'password'
        z '.make-visible', {
          onclick: =>
            @state.set isPasswordVisible: not isPasswordVisible
        },
          z @$eyeIcon,
            icon: 'eye'
            color: colors.$bgText
      else if opts.onInfo
        z '.make-visible', {
          onclick: ->
            opts.onInfo()
        },
          z @$eyeIcon,
            icon: 'help'
            color: colors.$bgText
