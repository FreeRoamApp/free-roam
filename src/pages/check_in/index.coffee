z = require 'zorium'
RxObservable = require('rxjs/Observable').Observable
require 'rxjs/add/observable/of'

AppBar = require '../../components/app_bar'
ButtonBack = require '../../components/button_back'
CheckIn = require '../../components/check_in'
Icon = require '../../components/icon'
colors = require '../../colors'

if window?
  require './index.styl'

module.exports = class CheckInPage
  hideDrawer: true

  constructor: ({@model, requests, @router, serverData}) ->
    checkIn = requests.switchMap ({route}) =>
      if route.params.id
        @model.checkIn.getById route.params.id
      else
        RxObservable.of null

    @$appBar = new AppBar {@model}
    @$buttonBack = new ButtonBack {@model, @router}
    @$checkIn = new CheckIn {@model, @router, checkIn}
    @$editIcon = new Icon()

    @state = z.state {
      checkIn
      me: @model.user.getMe()
    }

  getMeta: =>
    {checkIn} = @state.getValue()
    {
      title: @model.checkIn.getName checkIn
    }

  render: =>
    {me, checkIn} = @state.getValue()

    hasEditPermission = @model.checkIn.hasEditPermission checkIn, me

    z '.p-new-check-in',
      z @$appBar, {
        title: @model.checkIn.getLocation checkIn
        isPrimary: true
        $topLeftButton: z @$buttonBack, {
          color: colors.$primary500Text
        }
        $topRightButton:
          if checkIn?.id and hasEditPermission
            z @$editIcon,
              icon: 'edit'
              color: colors.$primary500Text
              hasRipple: true
              onclick: =>
                @router.go 'editCheckIn', {
                  id: checkIn.id
                }
      }
      @$checkIn
