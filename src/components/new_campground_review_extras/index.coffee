NewPlaceReviewExtras = require '../new_place_review_extras'

module.exports = class NewCampgroundReviewExtras extends NewPlaceReviewExtras
  allowedFields: ['roadDifficulty', 'crowds', 'fullness', 'noise', 'shade',
            'cleanliness', 'safety']
