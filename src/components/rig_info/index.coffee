z = require 'zorium'

EditRigDialog = require '../edit_rig_dialog'
config = require '../../config'

if window?
  require './index.styl'

module.exports = class RigInfo
  constructor: ({@model, @router}) ->
    @state = z.state {
      rig: @model.userRig.getByMe()
    }

  render: =>
    {rig} = @state.getValue()

    z '.z-rig-info',
      z '.info',
        z '.title', @model.l.get 'rigInfo.yourRig'
        z '.details',
          if rig?.type or rig?.length
            [
              if rig.length
                "#{rig.length}' "
              @model.l.get "rigs.#{rig.type}"
            ]
          else
            @model.l.get 'rigInfo.placeholder'

      z '.edit', {
        onclick: =>
          @model.overlay.open new EditRigDialog {@model, @router}
      },
        @model.l.get 'general.edit'
