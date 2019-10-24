z = require 'zorium'

FlatButton = require '../flat_button'
Icon = require '../icon'
colors = require '../../colors'

if window?
  require './index.styl'

module.exports = class SnackBar
  constructor: ({@model}) ->
    @$actionButton = new FlatButton()
    @$actionIcon = new Icon()
    @$closeIcon = new Icon()

    @state = z.state
      data: @model.statusBar.getData()

  render: ({hasBottomBar}) =>
    {data} = @state.getValue()

    z '.z-snack-bar', {
      className: z.classKebab {hasBottomBar}
    },
      z '.bar',
        z '.content',
          data?.text
        z '.actions',
          if data?.action?.icon
            z '.icon',
              z @$actionIcon,
                icon: data.action.icon
                isTouchTarget: false
                color: colors.$primaryMain
                onclick: data.action.onclick
          else if data?.action?.text
            z '.icon',
              z @$actionButton,
                text: data.action.text
                # color: colors.$primaryMain
                onclick: data.action.onclick
          z '.icon',
            z @$closeIcon,
              icon: 'close'
              isTouchTarget: false
              color: colors.$bgText54
              onclick: =>
                data?.onClose?()
                @model.statusBar.close()
