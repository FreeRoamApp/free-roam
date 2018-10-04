z = require 'zorium'
_defaults = require 'lodash/defaults'
_map = require 'lodash/map'
_range = require 'lodash/range'

Icon = require '../icon'
colors = require '../../colors'

if window?
  require './index.styl'

module.exports = class StepBar
  constructor: ({@model, @step}) ->

    @state = z.state
      step: @step

  render: ({cancel, save, steps, isStepCompleted, isLoading}) =>
    {step} = @state.getValue()

    cancel = _defaults cancel, {
      text: if step is 0 and cancel?.onclick \
            then @model.l.get 'general.cancel'
            else if step > 0
            then @model.l.get 'general.back'
            else ''
      onclick: -> null
    }
    save = _defaults save, {
      text: if step is steps - 1 \
            then @model.l.get 'general.save'
            else @model.l.get 'general.next'
      onclick: -> null
    }

    z '.z-step-bar',
      z '.g-grid',
        z '.previous', {
          onclick: =>
            if step > 0
              @step.next step - 1
            else
              cancel.onclick()
        },
          cancel.text

        z '.step-counter',
          _map _range(steps), (i) ->
            z '.step-dot',
              className: z.classKebab {isActive: step is i}

        z '.next', {
          className: z.classKebab {canContinue: isStepCompleted}
          onclick: =>
            if isStepCompleted
              if step is steps - 1
                save.onclick()
              else
                @step.next step + 1
        },
          if isLoading
          then @model.l.get 'general.loading'
          else save.text
