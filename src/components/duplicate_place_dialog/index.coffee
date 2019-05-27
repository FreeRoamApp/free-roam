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
  constructor: ({@model, place}) ->
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

    @model.placeBase.dedupe {
      sourceSlug: place.slug
      sourceType: place.type
      destinationSlug: @slugValue.getValue()
      destinationType: @typeValue.getValue()
    }
    .then =>
      @model.overlay.close()
      @state.set isSaving: false

  render: =>
    {isSaving} = @state.getValue()

    z '.z-duplicate-place-dialog',
      z @$dialog,
        isWide: true
        isVanilla: true
        $title: ''
        $content:
          z '.z-duplicate-place-dialog_dialog',
            z '.block',
              z 'label.label', @model.l.get 'editRigDialog.type'
              z @$typeDropdown,
                options: [
                  {value: 'campground', text: @model.l.get 'placeType.campground'}
                  {value: 'amenity', text: @model.l.get 'placeType.amenity'}
                  {value: 'overnight', text: @model.l.get 'placeType.overnight'}
                ]
            z '.block',
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
