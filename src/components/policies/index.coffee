z = require 'zorium'
_map = require 'lodash/map'
_defaults = require 'lodash/defaults'
Environment = require '../../services/environment'

Icon = require '../icon'
PrimaryButton = require '../primary_button'
Privacy = require '../privacy'
Tos = require '../tos'
colors = require '../../colors'
config = require '../../config'

if window?
  require './index.styl'

module.exports = class Policies
  constructor: ({@model, @router, isIab}) ->
    me = @model.user.getMe()

    @$privacy = new Privacy {@model, @router}
    @$tos = new Tos {@model, @router}
    @$continueButton = new PrimaryButton()

    $dropdowns = [
      {
        $title: 'Privacy Policy'
        $content: @$privacy
        $icon: new Icon()
        isVisible: false
      }
      {
        $title: 'Terms of Service'
        $content: @$tos
        $icon: new Icon()
        isVisible: false
      }
      {
        $title: 'Supercell Fan Content Policy'
        $content:
          z 'div', {style: {padding: '16px'}},
            'This content is not affiliated with, endorsed, sponsored,
            or specifically approved by Supercell and Supercell is not
            responsible for it. For more information see Supercell\'s Fan
            Content Policy: https://www.supercell.com/fan-content-policy.'
        $icon: new Icon()
        isVisible: false
      }
    ]

    @state = z.state
      $dropdowns: $dropdowns
      isIab: isIab

  render: =>
    {$dropdowns, isIab} = @state.getValue()

    z '.z-policies',
      z '.title', @model.l.get 'policies.title'
      z '.description',
        @model.l.get 'policies.description'

      _map $dropdowns, ($dropdown, i) =>
        {$content, $title, $icon, isVisible} = $dropdown
        [
          z '.divider'
          z '.dropdown',
            z '.block', {
              onclick: =>
                @state.set $dropdowns: _map $dropdowns, ($dropdown, j) ->
                  newIsContentVisible = if i is j \
                                        then not isVisible
                                        else false
                  _defaults {isVisible: newIsContentVisible}, $dropdown

            },
              z '.title', $title
              z '.icon',
                z $icon,
                  icon: 'expand-more'
                  isTouchTarget: false
                  color: colors.$primary500
            z '.content', {className: z.classKebab {isVisible}},
              $content
        ]

      unless isIab
        z '.continue-button',
          z @$continueButton,
            text: 'Continue'
            onclick: =>
              @router.goPath '/'
