z = require 'zorium'

UiCard = require '../ui_card'

if window?
  require './index.styl'

module.exports = class WalmartInfoCard
  constructor: ({@model, place}) ->
    @$uiCard = new UiCard()
    @state = z.state {
      place
      isAllowedByMe: place.switchMap (place) =>
        @model.overnight.getIsAllowedByMeAndId place.id
    }

  markIsAllowed: (isAllowed) =>
    {place} = @state.getValue()
    unless isAllowed is 'idk'
      @model.overnight.markIsAllowedById place.id, isAllowed

  render: =>
    {place, isAllowedByMe} = @state.getValue()

    z '.z-walmart-info-card',
      unless isAllowedByMe
        z @$uiCard, {
          $title: @model.l.get 'walmartInfoCard.title'
          $content: @model.l.get 'walmartInfoCard.content'
          cancel:
            text: @model.l.get 'general.no'
            onclick: =>
              @markIsAllowed false
          idk:
            text: @model.l.get 'general.idk'
            onclick: =>
              @markIsAllowed 'idk'
          submit:
            text: @model.l.get 'general.yes'
            onclick: =>
              @markIsAllowed true
        }
