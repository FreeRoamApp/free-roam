_map = require 'lodash/map'
z = require 'zorium'

if window?
  require './index.styl'

module.exports = class Form
  render: ({$inputs, $buttons, onsubmit}) ->
    z (if onsubmit then 'form.z-form' else '.z-form'), {
      onsubmit: onsubmit
    },
      [
        if $inputs
          _map $inputs, ($input, i) ->
            [
              z '.input', $input
              unless i is $inputs.length - 1
                z '.input-spacer'
            ]
        z '.spacer'
        if $buttons
          z '.buttons',
            _map $buttons, ($button) ->
              z '.button', $button
      ]
