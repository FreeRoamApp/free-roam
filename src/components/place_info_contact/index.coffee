z = require 'zorium'

if window?
  require './index.styl'

module.exports = class PlaceInfoContact
  constructor: ({@model, @router, place}) ->
    @state = z.state
      place: place

  render: =>
    {place} = @state.getValue()

    z '.z-place-info-contact',
      z '.coordinates',
        z 'span.title', "#{@model.l.get 'general.coordinates'}: "
        "#{place?.location?.lat}, #{place?.location?.lon}"

      if place?.contact?.phone
        matches = place.contact?.phone?.number.match(
          /^(\d{3})(\d{3})(\d{4})$/
        )
        phone = if matches
          "(#{matches[1]}) #{matches[2]}-#{matches[3]}"
        z '.phone',
          z 'span.title', @model.l.get 'place.phone'
          phone
      if place?.contact?.website
        z '.website',
          z 'span.title', @model.l.get 'place.website'
          z 'a', {
            href: place.contact?.website
            onclick: (e) =>
              e?.preventDefault()
              @model.portal.call 'browser.openWindow', {
                url: place.contact?.website
                target: '_system'
              }
          }, place.contact?.website
