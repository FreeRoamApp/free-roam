module.exports = class ThreadVote
  namespace: 'threadVotes'
  constructor: ({@auth}) -> null

  upsertByParent: (parent, {vote}) =>
    ga? 'send', 'event', 'social_interaction', 'thread_vote', "#{parent.type}"
    @auth.call "#{@namespace}.upsertByParent", {
      parent, vote
    }, {invalidateAll: true}
