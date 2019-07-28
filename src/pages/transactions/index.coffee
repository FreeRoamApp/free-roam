z = require 'zorium'

AppBar = require '../../components/app_bar'
ButtonBack = require '../../components/button_back'
Transactions = require '../../components/transactions'
colors = require '../../colors'

if window?
  require './index.styl'

module.exports = class TransactionsPage
  hideDrawer: true

  constructor: ({@model, requests, @router, serverData, group}) ->
    @$appBar = new AppBar {@model}
    @$backButton = new ButtonBack {@model, @router}
    @$transactions = new Transactions {@model, @router}

  getMeta: =>
    {
      title: @model.l.get 'transactionsPage.title'
      description: @model.l.get 'transactionsPage.title'
    }

  render: =>
    z '.p-transactions',
      z @$appBar, {
        title: @model.l.get 'transactionsPage.title'
        $topLeftButton: z @$backButton, {color: colors.$header500Icon}
      }
      @$transactions
