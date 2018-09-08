z = require 'zorium'
RxObservable = require('rxjs/Observable').Observable
require 'rxjs/add/observable/of'
_map = require 'lodash/map'

Icon = require '../icon'
Spinner = require '../spinner'
colors = require '../../colors'
config = require '../../config'

if window?
  require './index.styl'

module.exports = class Place
  constructor: ({@model, @router, place}) ->
    me = @model.user.getMe()

    @$spinner = new Spinner()

    @state = z.state
      place: place

  render: =>
    {place} = @state.getValue()

    console.log place

    z '.z-place',
      if place
        'place'
        z '.map' # TODO. test 2 maps 1 page? or yelp style where you click on it. probs that
      else
        z @$spinner
