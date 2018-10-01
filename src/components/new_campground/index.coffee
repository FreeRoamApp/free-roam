z = require 'zorium'

Icon = require '../icon'
colors = require '../../colors'
config = require '../../config'

if window?
  require './index.styl'

module.exports = class NewCampground
  constructor: ({@model, @router}) ->
    me = @model.user.getMe()

    @state = z.state {}

  render: =>
    {} = @state.getValue()

    z '.z-new-campground',
      z '.g-grid',
        'new camp'
        ###
        name
        location
        address?
        siteCount?
        crowds
        fullness
        noise
        shade
        roadDifficulty
        cellSignal
        safety
        minPrice (free)
        maxDays
        restrooms
        videos

        -> nearby amenities?
        ###
