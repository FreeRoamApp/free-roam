module.exports = class GiveawayEntry
  namespace: 'giveawayEntries'

  constructor: ({@auth}) -> null

  getAll: =>
    @auth.stream "#{@namespace}.getAll"
