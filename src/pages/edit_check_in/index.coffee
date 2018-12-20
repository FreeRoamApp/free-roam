z = require 'zorium'

AppBar = require '../../components/app_bar'
ButtonBack = require '../../components/button_back'
EditCheckIn = require '../../components/edit_check_in'
Icon = require '../../components/icon'
colors = require '../../colors'

if window?
  require './index.styl'

module.exports = class EditCheckInPage
  hideDrawer: true

  constructor: ({@model, requests, @router, serverData}) ->
    checkIn = requests.switchMap ({route}) =>
      @model.checkIn.getById route.params.id

    @$appBar = new AppBar {@model}
    @$buttonBack = new ButtonBack {@model, @router}
    @$editCheckIn = new EditCheckIn {@model, @router, checkIn}
    @$deleteIcon = new Icon()

    @state = z.state {checkIn}

  getMeta: =>
    {
      title: @model.l.get 'editCheckInPage.title'
    }

  render: =>
    {checkIn} = @state.getValue()

    z '.p-edit-check-in',
      z @$appBar, {
        title: @model.l.get 'editCheckInPage.title'
        style: 'primary'
        $topLeftButton: z @$buttonBack
        $topRightButton:
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
      @$editCheckIn
