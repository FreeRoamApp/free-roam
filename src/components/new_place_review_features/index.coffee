z = require 'zorium'
RxObservable = require('rxjs/Observable').Observable
require 'rxjs/add/observable/of'
_map = require 'lodash/map'

colors = require '../../colors'
config = require '../../config'

FEATURES = [
  'waterHookup'
  'sewerHookup'
  'dumpStation'
  '30amp'
  '50amp'
  'showers'
  'ada'
  'trash'
  'picnicTable'
  'flushToilet'
  'toilet'
  'petsAllowed'
  'wifi'
  'firePit'
  ''
  # 'firewood'
  # 'alcohol'

]

if window?
  require './index.styl'

module.exports = class PlaceNewReviewFeatures
  constructor: (options) ->
    {@model, @router, @fields, fieldsValues} = options
    me = @model.user.getMe()

    # TODO: features.valueStreams

    @state = z.state {
      me: @model.user.getMe()
      fieldsValues: fieldsValues
    }

  reset: =>
    null

  isCompleted: =>
    true

  getTitle: =>
    @model.l.get 'newReviewFeatures.title'

  render: =>
    {fieldsValues} = @state.getValue()

    z '.z-place-new-review-features',
      z '.g-grid',
        z '.description', @model.l.get 'newReviewFeatures.description'
        z '.features',
          _map FEATURES, (feature) =>
            isSelected = fieldsValues?.features and
              fieldsValues.features.indexOf(feature) isnt -1

            z '.feature', {
              className: z.classKebab {isSelected}
              onclick: =>
                if isSelected
                  index = fieldsValues.features.indexOf(feature)
                  features = fieldsValues.features
                  features.splice index, 1
                else
                  features = (fieldsValues?.features or []).concat feature
                @fields.features.valueStreams.next RxObservable.of features
            }, @model.l.get "feature.#{feature}"
