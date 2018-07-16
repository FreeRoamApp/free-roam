z = require 'zorium'

if window?
  require './index.styl'

module.exports = class UploadOverlay
  constructor: ({@model}) -> null

  render: ({onSelect}) ->
    z '.z-upload-overlay',
      z 'input#image.overlay',
        type: 'file'
        onchange: (e) ->
          e?.preventDefault()
          $$imageInput = document.getElementById('image')
          file = $$imageInput?.files[0]

          if file
            reader = new FileReader()
            reader.onload = (e) ->
              onSelect? {
                file: file
                dataUrl: e.target.result
              }

            reader.readAsDataURL file
