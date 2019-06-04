z = require 'zorium'

Dialog = require '../dialog'
config = require '../../config'
colors = require '../../colors'

if window?
  require './index.styl'

module.exports = class RequestRating
  constructor: ({@model}) ->
    @$dialog = new Dialog()

    @state = z.state {
      isLoading: false
    }

  afterMount: ->
    ga? 'send', 'event', 'requestRating', 'show'

  render: =>
    {isLoading} = @state.getValue()

    z '.z-request-rating',
        z @$dialog,
          isVanilla: true
          isWide: true
          $title: @model.l.get 'requestRating.title'
          $content: @model.l.get 'requestRating.text'
          cancelButton:
            text: @model.l.get 'general.no'
            isShort: true
            colors:
              cText: colors.$bgText54
            onclick: =>
              localStorage.hasSeenRequestRating = '1'
              @model.overlay.close()
          submitButton:
            text: @model.l.get 'requestRating.rate'
            isShort: true
            colors:
              cText: colors.$secondary500
            onclick: =>
              ga? 'send', 'event', 'requestRating', 'rate'
              localStorage.hasSeenRequestRating = '1'
              @state.set isLoading: true
              @model.portal.call 'app.rate'
              .then =>
                @state.set isLoading: false
                @model.overlay.close()
              .catch ->
                @state.set isLoading: false
