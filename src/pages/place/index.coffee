z = require 'zorium'

AppBar = require '../../components/app_bar'
ButtonBack = require '../../components/button_back'
BasePage = require '../base'
ReviewThanksDialog = require '../../components/review_thanks_dialog'
colors = require '../../colors'
config = require '../../config'

if window?
  require './index.styl'

module.exports = class PlacePage extends BasePage
  hideDrawer: true

  constructor: (options) ->
    {@model, @router, requests, serverData,
      group} = options

    @place = @clearOnUnmount requests.switchMap ({route}) =>
      @placeModel.getBySlug route.params.slug

    tab = requests.map ({route}) ->
      route.params.tab

    isNewReview = requests.map ({req}) ->
      req.query.newReview

    @$appBar = new AppBar {@model}
    @$buttonBack = new ButtonBack {@model, @router}
    @$place = new @Place {@model, @router, @place, tab}
    @$reviewThanksDialog = new ReviewThanksDialog {@model}

    @state = z.state
      place: @place
      isNewReview: isNewReview

  getMeta: =>
    @place.map (place) =>
      {
        title: @model.l.get 'placePage.title', {replacements: name: place?.name}
        description: @model.l.get 'placePage.description', {
          replacements:
            name: place?.name
            location: "#{place?.address?.locality}, #{place?.address?.administrativeArea}"
        }
        structuredData:
          type: 'LocalBusiness'
          name: place?.name
          ratingValue: place?.rating
          ratingCount: place?.ratingCount
      }

  render: =>
    {place, isNewReview} = @state.getValue()

    console.log isNewReview

    z '.p-place',
      z @$appBar, {
        title: place?.name
        isFlat: true
        style: 'primary'
        $topLeftButton: z @$buttonBack, {
          color: colors.$header500Icon
        }
      }
      @$place
      # if isNewReview
      #   z @$reviewThanksDialog
