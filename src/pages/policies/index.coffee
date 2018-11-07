z = require 'zorium'

Policies = require '../../components/policies'

if window?
  require './index.styl'

module.exports = class PoliciesPage
  hideDrawer: true

  constructor: ({@model, requests, @router, serverData, group}) ->
    isIab = requests.map ({req}) ->
      req.query.isIab

    @$policies = new Policies {@model, @router, isIab}

  getMeta: =>
    {
      title: @model.l.get 'policiesPage.title'
    }

  render: =>
    z '.p-policies',
      @$policies
