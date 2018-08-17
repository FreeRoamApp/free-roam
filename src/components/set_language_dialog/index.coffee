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
  constructor: ({@model, @router, @overlay$}) ->
    @$dialog = new Dialog()

    @languageStreams = new RxReplaySubject null
    @languageStreams.next @model.l.getLanguage()

    @state = z.state
      currentLanguage: @languageStreams.switch()
      languages: @model.l.getAll()

  render: =>
    {currentLanguage, languages} = @state.getValue()

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
            window.location.reload()
