module.exports = class ImageModel
  constructor: ->
    @loadedImages = []

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
