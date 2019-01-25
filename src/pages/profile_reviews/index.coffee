z = require 'zorium'

AppBar = require '../../components/app_bar'
ButtonBack = require '../../components/button_back'
ProfileReviews = require '../../components/profile_reviews'
config = require '../../config'
colors = require '../../colors'

if window?
  require './index.styl'

module.exports = class ProfileReviewsPage
  hideDrawer: true

  constructor: ({@model, @router, requests, serverData, group}) ->
    @user = requests.switchMap ({route}) =>
      @model.user.getByUsername route.params.username

    @$appBar = new AppBar {@model}
    @$buttonBack = new ButtonBack {@model, @router}
    @$profileReviews = new ProfileReviews {@model, @router, @user, type: 'user'}

    @state = z.state
      user: @user

  getMeta: =>
    @user.map (user) =>
      {
        title: @model.l.get 'profileReviewsPage.title', {
          replacements:
            name: @model.user.getDisplayName user
        }
        description: @model.l.get 'profileReviewsPage.description', {
          replacements:
            name: @model.user.getDisplayName user
        }
      }

  render: =>
    {user} = @state.getValue()

    z '.p-profile-reviews',
      z @$appBar, {
        title: if user
          @model.l.get 'profileReviewsPage.title', {
            replacements:
              name: @model.user.getDisplayName user
          }
        style: 'primary'
        $topLeftButton: z @$buttonBack, {color: colors.$header500Icon}
      }
      @$profileReviews
