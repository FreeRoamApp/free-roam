config = require '../config'

module.exports = class ImageModel
  constructor: ->
    @loadedImages = []
    # TODO: clear this out every once in a while (otherwise it's technically a memory leak)

  load: (url) =>
    new Promise (resolve, reject) =>
      preloadImage = new Image()
      preloadImage.src = url
      preloadImage.addEventListener 'load', =>
        @loadedImages.push url
        resolve()

  isLoaded: (url) =>
    # don't show for server-side otherwise it shows,
    # then hides, then shows again
    window? and @loadedImages.indexOf(url) isnt -1

  getSrcByPrefix: (prefix, size = 'small') ->
    unless prefix
      return ''
    "#{config.USER_CDN_URL}/#{prefix}.#{size}.jpg"
