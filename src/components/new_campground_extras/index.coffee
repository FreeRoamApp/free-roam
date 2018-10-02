z = require 'zorium'
RxBehaviorSubject = require('rxjs/BehaviorSubject').BehaviorSubject
_map = require 'lodash/map'
_every = require 'lodash/every'

InputRange = require '../input_range'
colors = require '../../colors'
config = require '../../config'

if window?
  require './index.styl'

module.exports = class NewCampgroundExtras
  constructor: ({@model, @router, @fields, @overlay$}) ->
    me = @model.user.getMe()


    @state = z.state {

    }

  isCompleted: =>
    false

  render: =>
    {} = @state.getValue()

    z '.z-new-campground-extras',
      z '.g-grid',
        'Extras'
