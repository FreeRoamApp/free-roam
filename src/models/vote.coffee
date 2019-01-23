module.exports = class Vote
  namespace: 'votes'
  constructor: ({@auth}) -> null

  upsertByParent: (parent, {vote}) =>
    ga? 'send', 'event', 'social_interaction', 'vote', "#{parent.type}"
    @auth.call "#{@namespace}.upsertByParent", {
      parent, vote
    }, {invalidateAll: true}
