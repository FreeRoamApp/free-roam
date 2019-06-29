z = require 'zorium'
RxReplaySubject = require('rxjs/ReplaySubject').ReplaySubject

Dialog = require '../dialog'
Checkbox = require '../checkbox'
Dropdown = require '../dropdown'
PrimaryInput = require '../primary_input'
colors = require '../../colors'
config = require '../../config'

if window?
  require './index.styl'


module.exports = class EditRigDialog
  constructor: ({@model}) ->
    userRig = @model.userRig.getByMe()

    @typeValueStreams = new RxReplaySubject 1
    @typeValueStreams.next userRig.map (userRig) ->
      userRig?.type
    @$typeDropdown = new Dropdown {valueStreams: @typeValueStreams}

    @lengthValueStreams = new RxReplaySubject 1
    @lengthValueStreams.next userRig.map (userRig) ->
      if userRig?.length then "#{userRig.length}" else ''
    @$lengthInput = new PrimaryInput {valueStreams: @lengthValueStreams}

    @is4x4ValueStreams = new RxReplaySubject 1
    @is4x4ValueStreams.next userRig.map (userRig) ->
      userRig?.is4x4
    @$is4x4Checkbox = new Checkbox {valueStreams: @is4x4ValueStreams}

    @$dialog = new Dialog {
      onLeave: =>
        @model.overlay.close()
    }

    @state = z.state
      isSaving: false
      type: @typeValueStreams.switch()
      length: @lengthValueStreams.switch()
      is4x4: @is4x4ValueStreams.switch()

  save: =>
    {type, length, is4x4} = @state.getValue()

    @state.set isSaving: true

    @model.userRig.upsert {
      type, length, is4x4
    }
    .then =>
      @model.overlay.close()
      @state.set isSaving: false

  render: =>
    {isSaving} = @state.getValue()

    z '.z-edit-rig-dialog',
      z @$dialog,
        isWide: true
        isVanilla: true
        $title: @model.l.get 'editRigDialog.title'
        $content:
          z '.z-edit-rig-dialog_dialog',
            z '.block',
              z 'label.label', @model.l.get 'editRigDialog.type'
              z @$typeDropdown,
                options: [
                  {value: '', text: ''}
                  {value: 'travelTrailer', text: @model.l.get 'rigs.travelTrailer'}
                  {value: 'fifthWheel', text: @model.l.get 'rigs.fifthWheel'}
                  {value: 'van', text: @model.l.get 'rigs.van'}
                  {value: 'classAMotorhome', text: @model.l.get 'rigs.classAMotorhome'}
                  {value: 'classBMotorhome', text: @model.l.get 'rigs.classBMotorhome'}
                  {value: 'classCMotorhome', text: @model.l.get 'rigs.classCMotorhome'}
                  {value: 'bus', text: @model.l.get 'rigs.bus'}
                  {value: 'truckCamper', text: @model.l.get 'rigs.truckCamper'}
                  {value: 'tent', text: @model.l.get 'rigs.tent'}
                  {value: 'car', text: @model.l.get 'rigs.car'}
                  {value: 'boxTruck', text: @model.l.get 'rigs.boxTruck'}
                  {value: 'motorcycle', text: @model.l.get 'rigs.motorcycle'}
                ]
            z '.block',
              # z 'label.label', @model.l.get 'editRigDialog.length'
              z @$lengthInput,
                hintText: @model.l.get 'editRigDialog.length'
                type: 'number'
            z '.block',
              z 'label.checkbox-label',
                z '.checkbox',
                  z @$is4x4Checkbox
                z '.text', @model.l.get 'editRigDialog.is4x4'
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
