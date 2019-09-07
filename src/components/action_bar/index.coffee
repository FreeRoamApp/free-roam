z = require 'zorium'
_defaults = require 'lodash/defaults'

AppBar = require '../app_bar'
Icon = require '../icon'
Environment = require '../../services/environment'
colors = require '../../colors'

if window?
  require './index.styl'

module.exports = class ActionBar
  constructor: ({@model}) ->
    @$appBar = new AppBar {@model}
    @$cancelIcon = new Icon()
    @$saveIcon = new Icon()

  render: ({title, cancel, save, isSaving, isPrimary, isSecondary}) =>
    cancel = _defaults cancel, {
      icon: 'close'
      text: @model.l.get 'general.cancel'
      onclick: -> null
    }
    save = _defaults save, {
      icon: 'check'
      text: @model.l.get 'general.save'
      # onclick: -> null
    }

    if isPrimary
      color = colors.$primary500Text
      bgColor = colors.$primary500
    else if isSecondary
      color = colors.$secondary500Text
      bgColor = colors.$secondary500
    else
      color = colors.$header500Icon
      bgColor = colors.$header500

    z '.z-action-bar',
      z @$appBar, {
        title: title
        isPrimary
        isSecondary
        $topLeftButton:
          z @$cancelIcon,
            icon: cancel.icon
            color: color
            hasRipple: true
            onclick: (e) ->
              e?.stopPropagation()
              cancel.onclick e
        $topRightButton:
          if save?.onclick
            z @$saveIcon,
              icon: if isSaving then 'ellipsis' else save.icon
              color: color
              hasRipple: true
              onclick: (e) ->
                e?.stopPropagation()
                save.onclick e
        isFlat: true
      }
