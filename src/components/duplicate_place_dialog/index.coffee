z = require 'zorium'
RxBehaviorSubject = require('rxjs/BehaviorSubject').BehaviorSubject

Dialog = require '../dialog'
Dropdown = require '../dropdown'
PrimaryInput = require '../primary_input'
colors = require '../../colors'
config = require '../../config'

if window?
  require './index.styl'


module.exports = class DuplicatePlaceDialog
  constructor: ({@model, @router, place}) ->
    @typeValue = new RxBehaviorSubject 'campground'
    @$typeDropdown = new Dropdown {value: @typeValue}

    @slugValue = new RxBehaviorSubject ''
    @$slugInput = new PrimaryInput {value: @slugValue}

    @$dialog = new Dialog {
      onLeave: =>
        @model.overlay.close()
    }

    @state = z.state
      place: place
      isSaving: false

  save: =>
    {place} = @state.getValue()
    @state.set isSaving: true

    typeValue = @typeValue.getValue()
    slugValue = @slugValue.getValue()

    @model.placeBase.dedupe {
      sourceSlug: place.slug
      sourceType: place.type
      destinationSlug: slugValue
      destinationType: typeValue
    }
    .then =>
      # @model.overlay.close()
      setTimeout =>
        place.type = typeValue
        place.slug = slugValue
        @router.goPlace place
      , 0
      @state.set isSaving: false

  render: =>
    {isSaving} = @state.getValue()

    z '.z-duplicate-place-dialog',
      z @$dialog,
        isWide: true
        isVanilla: true
        $title: @model.l.get 'duplicatePlaceDialog.title'
        $content:
          z '.z-duplicate-place-dialog_dialog',
            z '.block',
              z 'label.label', @model.l.get 'duplicatePlaceDialog.type'
              z @$typeDropdown,
                options: [
                  {value: 'campground', text: @model.l.get 'placeType.campground'}
                  {value: 'amenity', text: @model.l.get 'placeType.amenity'}
                  {value: 'overnight', text: @model.l.get 'placeType.overnight'}
                ]
            z '.block',
              z 'label.label', @model.l.get 'duplicatePlaceDialog.slug'
              z @$slugInput,
                hintText: @model.l.get 'duplicatePlaceDialog.destinationSlug'
                type: 'text'
        cancelButton:
          text: @model.l.get 'general.cancel'
          onclick: =>
            @model.overlay.close()
        submitButton:
          text: if isSaving \
                then @model.l.get 'general.loading'
                else @model.l.get 'general.save'
          onclick: =>
            @save()
