z = require 'zorium'
RxObservable = require('rxjs/Observable').Observable
require 'rxjs/add/observable/of'
_isEmpty = require 'lodash/isEmpty'
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

    @state = z.state {
      me: @model.user.getMe()
      user
      attachments
    }

  render: =>
    {me, user, attachments} = @state.getValue()

    isMe = user and user?.id is me?.id

    z '.z-profile-attachments',
      if attachments and _isEmpty attachments
        z '.empty',
          z '.g-grid',
            if isMe
              @model.l.get 'profileAttachments.meEmpty'
            else
              @model.l.get 'profileAttachments.empty', {
                replacements:
                  name: @model.user.getDisplayName user
              }
      z @$attachments
