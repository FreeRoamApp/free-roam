config = require '../config'

module.exports = class ImageModel
  constructor: ({@additionalScript}) ->
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

  getSrcByPrefix: (prefix, {size, cacheBust} = {}) ->
    size ?= 'small'

    unless prefix
      return ''
    src = "#{config.USER_CDN_URL}/#{prefix}.#{size}.jpg"
    if cacheBust
      src += "?#{cacheBust}"
    src


  parseExif: (file, locationValueSubject, rotationValueSubject) =>
    if file.type.indexOf('jpeg') isnt -1
      @additionalScript.add(
        'js', 'https://fdn.uno/d/scripts/exif-parser.min.js'
      ).then ->
        reader = new FileReader()
        reader.onload = (e) ->
          parser = window.ExifParser.create(e.target.result)
          parser.enableSimpleValues true
          result = parser.parse()
          rotation = switch result.tags.Orientation
                          when 3 then 'rotate-180'
                          when 8 then 'rotate-270'
                          when 6 then 'rotate-90'
                          else ''
          location = if result.tags.GPSLatitude \
                     then {lat: result.tags.GPSLatitude, lon: result.tags.GPSLongitude}
                     else null
          rotationValueSubject?.next rotation
          locationValueSubject?.next location
        reader.readAsArrayBuffer file
