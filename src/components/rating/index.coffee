z = require 'zorium'
RxBehaviorSubject = require('rxjs/BehaviorSubject').BehaviorSubject
RxObservable = require('rxjs/Observable').Observable
require 'rxjs/add/observable/of'
_map = require 'lodash/map'
_range = require 'lodash/range'

Icon = require '../icon'
colors = require '../../colors'

if window?
  require './index.styl'

module.exports = class Rating
  # set isInteractive to true if tapping on a star should fill up to that star
  constructor: ({@value, @valueStreams, @isInteractive, @onRate}) ->
    @value ?= new RxBehaviorSubject 0

    @$icons = [new Icon(), new Icon(), new Icon(), new Icon(), new Icon()]

    rating = @valueStreams?.switch() or @value

    @state = z.state {
      rating: rating
      starIcons: rating.map (rating) ->
        rating ?= 0
        halfStars = Math.round(rating * 2)
        fullStars = Math.floor(halfStars / 2)
        halfStars -= fullStars * 2
        emptyStars = 5 - (fullStars + halfStars)
        _map _range(fullStars), -> 'star'
        .concat _map _range(halfStars), -> 'star-half'
        .concat _map _range(emptyStars), -> 'star-outline'
    }

  setRating: (value) =>
    if @valueStreams
      @valueStreams.next RxObservable.of value
    else
      @value.next value
    @onRate? value

  render: ({size, color} = {}) =>
    {rating, starIcons} = @state.getValue()

    size ?= '20px'
    color ?= colors.$amber500

    z '.z-rating', {
      style:
        height: size
    },
      _map starIcons, (icon, i) =>
        z '.star',
          z @$icons[i],
            icon: icon
            size: size
            isTouchTarget: false
            color: color
            onclick: if @isInteractive then (=> @setRating i + 1) else null
