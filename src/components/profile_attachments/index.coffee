z = require 'zorium'
RxObservable = require('rxjs/Observable').Observable
require 'rxjs/add/observable/of'
_startCase = require 'lodash/startCase'

Attachments = require '../attachments'
colors = require '../../colors'
config = require '../../config'

if window?
  require './index.styl'

module.exports = class ProfileAttachments
  constructor: ({@model, @router, user}) ->
    attachments = user.switchMap (user) =>
      unless user
        return RxObservable.of null
      @model.placeAttachment.getAllByUserId user.id

    @$attachments = new Attachments {
      @model, @router, attachments
    }

    @state = z.state {user}

  render: =>
    {user} = @state.getValue()

    z '.z-profile-attachments',
      z @$attachments
