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

  render: ({title, cancel, save, isSaving}) =>
    cancel = _defaults cancel, {
      icon: 'close'
      text: @model.l.get 'general.cancel'
      onclick: -> null
    }
    save = _defaults save, {
      icon: 'check'
      text: @model.l.get 'general.save'
      onclick: -> null
    }


    z '.z-action-bar', {
      onclick: ->
        if Environment.isIos()
          document.activeElement.blur()
    },
      z @$appBar, {
        title: title
        style: 'primary'
        $topLeftButton:
          z @$cancelIcon,
            icon: cancel.icon
            color: colors.$header500Icon
            hasRipple: true
            onclick: (e) ->
              e?.stopPropagation()
              cancel.onclick e
        $topRightButton:
          z @$saveIcon,
            icon: if isSaving then 'ellipsis' else save.icon
            color: colors.$header500Icon
            hasRipple: true
            onclick: (e) ->
              e?.stopPropagation()
              save.onclick e
        isFlat: true
      }
