z = require 'zorium'
RxObservable = require('rxjs/Observable').Observable
require 'rxjs/add/observable/of'
_map = require 'lodash/map'
_isEmpty = require 'lodash/isEmpty'

EmbeddedVideo = require '../embedded_video'
FormattedText = require '../formatted_text'
Spinner = require '../spinner'
colors = require '../../colors'
config = require '../../config'

if window?
  require './index.styl'

module.exports = class ItemGuide
  constructor: ({@model, @router, item}) ->
    me = @model.user.getMe()

    @$spinner = new Spinner()

    @state = z.state
      item: item
      $why: new FormattedText {
        text: item.map (item) -> item?.why
      }
      $what: new FormattedText {
        text: item.map (item) -> item?.what
      }
      $videos: item.map (item) =>
        _map item?.videos, (video) =>
          new EmbeddedVideo {@model, video}

  render: =>
    {item, products, $why, $what, $videos} = @state.getValue()

    z '.z-item-guide',
      if item?.name
        z '.g-grid',
          z '.why',
            z '.title', @model.l.get 'item.why'
            $why
          z '.what',
            z '.title', @model.l.get 'item.what'
            $what
          unless _isEmpty item.videos
            [
              z '.title', @model.l.get 'item.helpfulVideos'
              _map $videos, ($video) ->
                z $video
            ]
      else
        z @$spinner
