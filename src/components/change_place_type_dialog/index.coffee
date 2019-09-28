z = require 'zorium'
RxReplaySubject = require('rxjs/ReplaySubject').ReplaySubject
RxObservable = require('rxjs/Observable').Observable
require 'rxjs/add/observable/of'

Dialog = require '../dialog'
Dropdown = require '../dropdown'
PrimaryInput = require '../primary_input'
colors = require '../../colors'
config = require '../../config'

if window?
  require './index.styl'


module.exports = class ChangePlaceTypeDialog
  constructor: ({@model, @router, place}) ->
    @typeValueStreams = new RxReplaySubject 1
    @typeValueStreams.next RxObservable.of place?.type
    @$typeDropdown = new Dropdown {valueStreams: @typeValueStreams}

    @$dialog = new Dialog {
      onLeave: =>
        @model.overlay.close()
    }

    @state = z.state
      place: place
      typeValue: @typeValueStreams.switch()
      isSaving: false

  save: =>
    {place, typeValue} = @state.getValue()
    @state.set isSaving: true

    @model.placeBase.changeType {
      sourceSlug: place.slug
      sourceType: place.type
      destinationType: typeValue
    }
    .then =>
      # @model.overlay.close()
      setTimeout =>
        place.type = typeValue
        @router.goPlace place
      , 0
      @state.set isSaving: false

  render: =>
    {isSaving} = @state.getValue()

    z '.z-change-place-type-dialog',
      z @$dialog,
        isWide: true
        isVanilla: true
        $title: @model.l.get 'duplicatePlaceDialog.title'
        $content:
          z '.z-change-place-type-dialog_dialog',
            z '.block',
              z 'label.label', @model.l.get 'duplicatePlaceDialog.type'
              z @$typeDropdown,
                options: [
                  {
                    value: 'campground'
                    text: @model.l.get 'placeType.campground'
                  }
                  {
                    value: 'amenity'
                    text: @model.l.get 'placeType.amenity'
                  }
                  {
                    value: 'overnight'
                    text: @model.l.get 'placeType.overnight'
                  }
                ]
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
