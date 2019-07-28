z = require 'zorium'
_isEmpty = require 'lodash/isEmpty'

AppBar = require '../../components/app_bar'
ButtonBack = require '../../components/button_back'
Donate = require '../../components/donate'
FlatButton = require '../../components/flat_button'
config = require '../../config'
colors = require '../../colors'

if window?
  require './index.styl'

module.exports = class DonatePage
  hideDrawer: true

  constructor: ({@model, @router, requests, serverData}) ->
    @$appBar = new AppBar {@model}
    @$buttonBack = new ButtonBack {@model, @router}
    @$donate = new Donate {@model, @router}
    @$transactionsButton = new FlatButton()

    @state = z.state {
      transactions: @model.transaction.getAll()
    }

  getMeta: =>
    {
      title: @model.l.get 'general.donate'
      description: ''
    }

  render: =>
    {transactions} = @state.getValue()

    z '.p-donate',
      z @$appBar, {
        title: @model.l.get 'general.donate'
        style: 'primary'
        $topLeftButton: z @$buttonBack, {color: colors.$header500Icon}
        $topRightButton:
          unless _isEmpty transactions
            z @$transactionsButton, {
              onclick: =>
                @router.go 'transactions'
              colors:
                cText: colors.$secondary500
              text: @model.l.get 'general.transactions'
            }
      }
      @$donate
