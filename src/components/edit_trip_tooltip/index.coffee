z = require 'zorium'
RxBehaviorSubject = require('rxjs/BehaviorSubject').BehaviorSubject

Icon = require '../icon'
FlatButton = require '../flat_button'
MapTooltip = require '../map_tooltip'
MapService = require '../../services/map'
colors = require '../../colors'

if window?
  require './index.styl'

module.exports = class EditTripTooltip extends MapTooltip
  constructor: ({@model, @router, @place, @position, @mapSize, @onSave}) ->
    @$closeIcon = new Icon()
    @$actionButton = new FlatButton()
    @size = new RxBehaviorSubject {width: 0, height: 0}

    @state = z.state {
      @place
      @mapSize
      @size
      isSaving: false
      isSaved: false
    }

    super

  getThumbnailUrl: (place) ->
    null

  render: ({isVisible} = {}) =>
    {place, mapSize, size, isSaving, isSaved} = @state.getValue()

    isVisible ?= Boolean place and Boolean size.width

    anchor = @getAnchor place?.position, mapSize, size
    transform = @getTransform place?.position, anchor

    z ".z-edit-trip-tooltip.anchor-#{anchor}", {
      className: z.classKebab {isVisible, @isImageLoaded}
      style:
        transform: transform
        webkitTransform: transform
    },
      z '.close',
        z @$closeIcon,
          icon: 'close'
          size: '16px'
          isTouchTarget: false
          color: colors.$bgText54
          onclick: (e) =>
            e?.stopPropagation()
            e?.preventDefault()
            @place.next null
      z '.content',
        z '.title', place?.name
        if place?.description
          z '.description', place?.description
      z '.actions',
        z '.action',
          z @$actionButton, {
            onclick: =>
              @state.set isSaving: true
              @onSave place
              .then =>
                @state.set isSaved: true, isSaving: false
            text:
              if isSaving then @model.l.get 'general.saving'
              else if isSaved then @model.l.get 'general.saved'
              else @model.l.get 'editTripTooltip.addToTrip'
          }
