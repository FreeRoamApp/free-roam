z = require 'zorium'
_map = require 'lodash/map'
RxReplaySubject = require('rxjs/ReplaySubject').ReplaySubject
RxObservable = require('rxjs/Observable').Observable
require 'rxjs/add/observable/of'
require 'rxjs/add/operator/switch'

Dialog = require '../dialog'
colors = require '../../colors'
config = require '../../config'

if window?
  require './index.styl'

module.exports = class SetLanguageDialog
  constructor: ({@model, @router, @overlay$, group}) ->
    @$dialog = new Dialog()

    @languageStreams = new RxReplaySubject null
    @languageStreams.next @model.l.getLanguage()

    @state = z.state
      group: group
      currentLanguage: @languageStreams.switch()
      languages: @model.l.getAll()

  render: =>
    {group, currentLanguage, languages} = @state.getValue()

    gameKey = group?.gameKey or group?.gameKeys?[0]
    isGameGroup = group?.gameKey

    z '.z-set-language-dialog',
      z @$dialog,
        isVanilla: true
        isWide: true
        onLeave: =>
          @overlay$.next null
        $title: @model.l.get 'setLanguageDialog.title'
        $content:
          z '.z-set-language-dialog_dialog',
            _map languages, (language) =>
              z 'label.option',
                z 'input.radio',
                  type: 'radio'
                  name: 'sort'
                  value: language
                  checked: currentLanguage is language
                  onchange: =>
                    @languageStreams.next RxObservable.of language
                z '.text',
                  @model.l.get language, {file: 'languages'}

        cancelButton:
          text: @model.l.get 'general.cancel'
          onclick: =>
            @overlay$.next null

        submitButton:
          text: @model.l.get 'general.save'
          onclick: =>
            @model.l.setLanguage currentLanguage
            @model.user.setLanguage currentLanguage
            @overlay$.next null
            # we use a separate bundle.js per language, so need to load that in
            # also need to switch to correct group
            if gameKey and isGameGroup
              @model.cookie.set 'routerLastPath', ''
              @model.cookie.set 'lastGroupId', ''
              window.location.href = "/game/#{gameKey}"
            else
              window.location.reload()
