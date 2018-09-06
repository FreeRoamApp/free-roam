z = require 'zorium'
_map = require 'lodash/map'
RxObservable = require('rxjs/Observable').Observable
require 'rxjs/add/observable/of'

Map = require '../../components/map'
colors = require '../../colors'
config = require '../../config'

if window?
  require './index.styl'

module.exports = class Places
  constructor: ({@model, @router, filter}) ->
    me = @model.user.getMe()
    @$map = new Map {@model, @router}

    @state = z.state
      filter: null # TODO


  render: =>
    {} = @state.getValue()

    z '.z-places',
      z @$map
