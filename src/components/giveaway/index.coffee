z = require 'zorium'
_map = require 'lodash/map'
_isEmpty = require 'lodash/isEmpty'
_startCase = require 'lodash/startCase'
_sum = require 'lodash/sum'
_values = require 'lodash/values'

Icon = require '../icon'
DateService = require '../../services/date'
colors = require '../../colors'
config = require '../../config'

if window?
  require './index.styl'

module.exports = class Giveaway
  constructor: ({@model, @router}) ->
    me = @model.user.getMe()

    @state = z.state
      me: me
      entries: @model.giveawayEntry.getAll()

  render: =>
    {me, entries} = @state.getValue()

    total = _sum _values(entries)

    z '.z-giveaway',
      z '.title', 'Want to win a $25 Amazon gift card?'
      z 'ul',
        z 'li', 'Just participate in one of the communities on FreeRoam and you\'ll be entered to win'
        z 'li', 'Head back to the "Social" page, pick a group, and post in either the chat or forum.'
        z 'li', 'Each post, up to 3 per day, gets you an entry.'
      z '.description',
        'At the end of the week we\'ll randomly choose one winner. '
        z 'span.time-left',
          'Time left: '
          # TODO
      z '.entries',
        z '.title', 'Here are your entries for this week:'
        _map entries, (count, action) ->
          z '.entry',
            z '.action',
              if action is 'firstSocialPost'
                'Referral'
              else
                _startCase action
            z '.count', count
        if _isEmpty entries
          z '.placeholder', "You don't have any entries this week. Earn by posting in chat or the forum"
        else
          z '.entry.total',
            z '.action', 'Total'
            z '.count', total
