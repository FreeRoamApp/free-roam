z = require 'zorium'
_find = require 'lodash/find'
_filter = require 'lodash/filter'

Icon = require '../icon'
DateService = require '../../services/date'
colors = require '../../colors'
config = require '../../config'

if window?
  require './index.styl'

module.exports = class Author
  constructor: ({@model, @router, @$body}) ->
    null

  render: ({user, groupUser, time, isTimeAlignedLeft, onclick}) =>
    z '.z-action-message', {onclick},
      z '.name',
        @model.user.getDisplayName user
      z '.message',
        z @$body
      z '.time', {
        className: z.classKebab {isAlignedLeft: isTimeAlignedLeft}
      },
        if time
        then DateService.fromNow time
        else '...'
