ReviewBase = require './review_base'

module.exports = class PlaceReviewBase extends ReviewBase
  namespace: 'placeReviews'

  getAllByUserId: (userId) =>
    @auth.stream "#{@namespace}.getAllByUserId", {userId}

  getCountByUserId: (userId) =>
    @auth.stream "#{@namespace}.getCountByUserId", {userId}

  upsertRatingOnly: (options, {invalidateAll} = {}) =>
    invalidateAll ?= true
    @auth.call "#{@namespace}.upsertRatingOnly", options, {invalidateAll}
