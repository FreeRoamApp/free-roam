module.exports = class UserFollower
  namespace: 'userFollowers'

  constructor: ({@auth}) -> null

  getAllFollowingIds: =>
    @auth.stream "#{@namespace}.getAllFollowingIds", {}

  getAllFollowerIds: =>
    @auth.stream "#{@namespace}.getAllFollowerIds", {}

  getAllFollowing: =>
    @auth.stream "#{@namespace}.getAllFollowing", {}

  getAllFollowers: =>
    @auth.stream "#{@namespace}.getAllFollowers", {}

  followByUserId: (userId) =>
    @auth.call "#{@namespace}.followByUserId", {userId}, {invalidateAll: true}

  unfollowByUserId: (userId) =>
    @auth.call "#{@namespace}.unfollowByUserId", {userId}, {invalidateAll: true}

  isFollowing: (followingIds, userId) ->
    followingIds.indexOf(userId) isnt -1
