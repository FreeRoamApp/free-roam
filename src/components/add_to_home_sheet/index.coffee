z = require 'zorium'

Sheet = require '../sheet'

module.exports = class AddToHomeSheet
  constructor: ({@model, router, @isVisible}) ->
    @$sheet = new Sheet {@model, router, @isVisible}


  render: ({message}) =>
    z '.z-add-to-home-sheet',
      z @$sheet, {
        message: message
        icon: 'home'
        submitButton:
          text: @model.l.get 'addToHomeSheet.submitButton'
          onclick: =>
            @model.portal.call 'app.install'
            @isVisible.next false
      }
