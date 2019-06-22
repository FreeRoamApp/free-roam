z = require 'zorium'

config = require '../../config'

if window?
  require './index.styl'

module.exports = class Preservation
  constructor: ({@model, @router}) ->
    @state = z.state {}

  render: =>
    {} = @state.getValue()

    z '.z-preservation',
      z '.top',
        z '.g-grid',
          z 'h1.title', @model.l.get 'preservation.title'
          z '.description', @model.l.get 'preservation.description'
      z '.content',
        z '.lesson',
          z '.g-grid',
            z '.icon.pack-out'
            z '.title', @model.l.get 'preservation.packOutTitle'
            z '.description', @model.l.get 'preservation.packOut'
            z 'ul.bullets',
              z 'li', @model.l.get 'preservation.packOutBullet1'
              z 'li', @model.l.get 'preservation.packOutBullet2'
              z 'li', @model.l.get 'preservation.packOutBullet3'
              z 'li', @model.l.get 'preservation.packOutBullet4'
        z '.lesson',
          z '.g-grid',
            z '.icon.fire-safety'
            z '.title', @model.l.get 'preservation.fireSafetyTitle'
            z '.description', @model.l.get 'preservation.fireSafety'
            z 'ul.bullets',
              z 'li', @model.l.get 'preservation.fireSafetyBullet1'
              z 'li', @model.l.get 'preservation.fireSafetyBullet2'
        z '.lesson',
          z '.g-grid',
            z '.icon.trails'
            z '.title', @model.l.get 'preservation.trailsTitle'
            z '.description', @model.l.get 'preservation.trails'
            z 'ul.bullets',
              z 'li', @model.l.get 'preservation.trailsBullet1'
        z '.lesson',
          z '.g-grid',
            z '.icon.stay-limit'
            z '.title', @model.l.get 'preservation.stayLimitTitle'
            z '.description', @model.l.get 'preservation.stayLimit'
