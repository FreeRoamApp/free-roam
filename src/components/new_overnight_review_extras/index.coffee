NewPlaceReviewExtras = require '../new_place_review_extras'

module.exports = class NewOvernightReviewExtras extends NewPlaceReviewExtras
  allowedFields: ['noise', 'safety']
