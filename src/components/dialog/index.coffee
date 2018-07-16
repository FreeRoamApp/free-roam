z = require 'zorium'
_isEmpty = require 'lodash/isEmpty'
_map = require 'lodash/map'
_defaults = require 'lodash/defaults'

if window?
  require './index.styl'

FlatButton = require '../flat_button'
colors = require '../../colors'

module.exports = class Dialog
  constructor: ->
    @$cancelButton = new FlatButton()
    @$submitButton = new FlatButton()

  render: (props) =>
    {$content, $title, cancelButton, submitButton, isVanilla,
      isWide, onLeave} = props
    $content ?= ''
    onLeave ?= (-> null)

    z '.z-dialog', {className: z.classKebab {isVanilla, isWide}},
      z '.backdrop', onclick: ->
        onLeave()

      z '.dialog',
        z '.content',
          if $title
            z '.title',
              $title
          $content
        if cancelButton or submitButton
          z '.actions',
            if cancelButton
              z '.action', {
                className: z.classKebab {isFullWidth: cancelButton.isFullWidth}
              },
                z @$cancelButton, _defaults cancelButton, {
                  colors: {cText: colors.$primary500}
                }
            if submitButton
              z '.action',
                z @$submitButton, _defaults submitButton, {
                  colors: {cText: colors.$primary500}
                }
