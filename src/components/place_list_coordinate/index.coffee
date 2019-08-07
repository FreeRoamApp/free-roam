z = require 'zorium'

colors = require '../../colors'
config = require '../../config'

if window?
  require './index.styl'

module.exports = class PlaceListItem
  constructor: ({@model, @router, @place, @action}) ->
    @defaultImages = [
      "#{config.CDN_URL}/places/empty_campground.svg"
      "#{config.CDN_URL}/places/empty_campground_green.svg"
      "#{config.CDN_URL}/places/empty_campground_blue.svg"
      "#{config.CDN_URL}/places/empty_campground_beige.svg"
    ]

    @state = z.state
      me: @model.user.getMe()
      place: @place

  getThumbnailUrl: (place) =>
    lastChar = place?.id?.substr(place?.id?.length - 1, 1) or 'a'
    @defaultImages[\
      Math.ceil (parseInt(lastChar, 16) / 16) * (@defaultImages.length - 1)
    ]

  render: =>
    {me, place} = @state.getValue()

    place ?= @place

    thumbnailSrc = @getThumbnailUrl place

    z '.z-place-list-campground',
      z '.thumbnail',
        style:
          backgroundImage: "url(#{thumbnailSrc})"
      z '.info',
        z '.name',
          place?.name
        if place?.address?.administrativeArea
          z '.location',
            if place?.address?.locality
              "#{place?.address?.locality}, "
            place?.address?.administrativeArea
