ReviewBase = require './review_base'

module.exports = class PlaceReviewBase extends ReviewBase
  namespace: 'placeReviews'

  getAllByUserId: (userId) =>
    @auth.stream "#{@namespace}.getAllByUserId", {userId}

  getByUserIdAndParentId: (userId, parentId) =>
    @auth.stream "#{@namespace}.getByUserIdAndParentId", {userId, parentId}

  getCountByUserId: (userId) =>
    @auth.stream "#{@namespace}.getCountByUserId", {userId}

  upsertRatingOnly: (options, {invalidateAll} = {}) =>
    invalidateAll ?= true
    ga? 'send', 'event', 'ugc', 'ratingOnly', options.parentId
    @auth.call "#{@namespace}.upsertRatingOnly", options, {invalidateAll}
