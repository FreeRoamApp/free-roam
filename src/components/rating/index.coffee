z = require 'zorium'
RxBehaviorSubject = require('rxjs/BehaviorSubject').BehaviorSubject
_map = require 'lodash/map'
_range = require 'lodash/range'

Icon = require '../icon'
colors = require '../../colors'

if window?
  require './index.styl'

module.exports = class Rating
  # set isInteractive to true if tapping on a star should fill up to that star
  constructor: ({@rating, @isInteractive}) ->
    @rating ?= new RxBehaviorSubject 0

    @$icons = [new Icon(), new Icon(), new Icon(), new Icon(), new Icon()]

    @state = z.state {
      @rating
      starIcons: @rating.map (rating) ->
        console.log rating
        rating ?= 0
        halfStars = Math.round(rating * 2)
        fullStars = Math.floor(halfStars / 2)
        halfStars -= fullStars * 2
        emptyStars = 5 - (fullStars + halfStars)
        _map _range(fullStars), -> 'star'
        .concat _map _range(halfStars), -> 'star-half'
        .concat _map _range(emptyStars), -> 'star-outline'
    }

  setRating: (stars) ->
    @rating.next stars

  getRating: =>
    @rating.getValue()

  render: ({size} = {}) =>
    {rating, starIcons} = @state.getValue()

    size ?= '20px'

    z '.z-rating', _map starIcons, (icon, i) =>
      rating = i + 1
      z '.star',
        z @$icons[i],
          icon: icon
          size: size
          isTouchTarget: false
          color: colors.$primary500
          onclick: =>
            if @isInteractive
              @setRating rating
