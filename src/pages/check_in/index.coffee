z = require 'zorium'
RxObservable = require('rxjs/Observable').Observable
require 'rxjs/add/observable/of'
_defaults = require 'lodash/defaults'

AppBar = require '../../components/app_bar'
ButtonBack = require '../../components/button_back'
CheckIn = require '../../components/check_in'
Icon = require '../../components/icon'
DateService = require '../../services/date'
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
    @$deleteIcon = new Icon()

    @state = z.state {
      checkIn: checkIn.map (checkIn) ->
        _defaults {
          startTime: DateService.format new Date(checkIn.startTime), 'MMM D'
          endTime: DateService.format new Date(checkIn.endTime), 'MMM D'
        }, checkIn
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
        title: if checkIn?.endTime and checkIn.endTime isnt checkIn.startTime
          "#{checkIn.startTime} - #{checkIn.endTime}"
        else if checkIn?.startTime
          checkIn.startTime
        isPrimary: true
        $topLeftButton: z @$buttonBack, {
          color: colors.$primary500Text
        }
        $topRightButton:
          if checkIn?.id and hasEditPermission
            z '.p-new-check-in_top-right',
              z @$editIcon,
                icon: 'edit'
                color: colors.$primary500Text
                hasRipple: true
                onclick: =>
                  @router.go 'editCheckIn', {
                    id: checkIn.id
                  }

              z @$deleteIcon,
                icon: 'delete'
                color: colors.$header500Icon
                hasRipple: true
                onclick: =>
                  if confirm @model.l.get 'general.confirm'
                    @model.checkIn.deleteByRow checkIn
                    .then =>
                      @router.back()
      }
      @$checkIn
