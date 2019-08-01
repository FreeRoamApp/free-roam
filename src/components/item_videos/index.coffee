z = require 'zorium'
_map = require 'lodash/map'

EmbeddedVideo = require '../embedded_video'
Spinner = require '../spinner'
colors = require '../../colors'
config = require '../../config'

if window?
  require './index.styl'

module.exports = class ItemVideos
  constructor: ({@model, @router, item}) ->
    me = @model.user.getMe()

    @$spinner = new Spinner()

    @state = z.state
      item: item
      videos: item.map (item) =>
        _map item?.videos, (video) =>
          {
            video: video
            $video: new EmbeddedVideo {@model, video}
          }

  render: =>
    {item, videos} = @state.getValue()

    z '.z-item-videos',
      z '.g-grid',
        if videos
          [
            z '.title', @model.l.get 'item.helpfulVideos'
            _map videos, ({$video, video}) ->
              z '.video',
                z '.name', video.name
                z $video
          ]
        else
          z @$spinner
