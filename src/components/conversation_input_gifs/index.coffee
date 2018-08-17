z = require 'zorium'
_map = require 'lodash/map'
_shuffle = require 'lodash/shuffle'
_startCase = require 'lodash/startCase'
supportsWebP = window? and require 'supports-webp'
RxBehaviorSubject = require('rxjs/BehaviorSubject').BehaviorSubject
RxObservable = require('rxjs/Observable').Observable
require 'rxjs/add/observable/of'
require 'rxjs/add/observable/combineLatest'
require 'rxjs/add/operator/filter'
require 'rxjs/add/operator/switchMap'
require 'rxjs/add/operator/take'
require 'rxjs/add/operator/map'
require 'rxjs/add/operator/debounceTime'

SearchInput = require '../search_input'
Spinner = require '../spinner'
colors = require '../../colors'

if window?
  require './index.styl'

SEARCH_DEBOUNCE = 300

module.exports = class ConversationInputGifs
  constructor: ({@model, @message, @onPost, @currentPanel, group}) ->
    @searchValue = new RxBehaviorSubject null
    debouncedSearchValue = @searchValue.debounceTime(SEARCH_DEBOUNCE)

    @$searchInput = new SearchInput {@model, @searchValue}
    @$spinner = new Spinner()

    currentPanelAndSearchValueAndGroup = RxObservable.combineLatest(
      @currentPanel
      debouncedSearchValue
      group
      (vals...) -> vals
    )
    gifs = currentPanelAndSearchValueAndGroup
    .switchMap ([currentPanel, query, group]) =>
      if currentPanel is 'gifs'
        query or= _startCase group?.gameKeys?[0]
        @state.set isLoadingGifs: true
        search = @model.gif.search query, {
          limit: 25
          offset: 0
        }
        search.take(1).subscribe =>
          @state.set isLoadingGifs: false
        search.map (results) -> _shuffle results?.data
      else
        RxObservable.of null

    @state = z.state
      gifs: gifs
      isLoadingGifs: false
      windowSize: @model.window.getSize()

  getHeightPx: ->
    RxObservable.of 154

  render: =>
    {gifs, isLoadingGifs, windowSize} = @state.getValue()

    z '.z-conversation-input-gifs',
      z @$searchInput, {
        isSearchIconRight: true
        height: '36px'
        bgColor: colors.$tertiary500
        placeholder: @model.l.get 'conversationInputGifs.hintText'
      }
      z '.gifs', {
        # style: width: "#{windowSize.width - drawerWidth}px"
        ontouchstart: (e) ->
          e?.stopPropagation()
      },
        if isLoadingGifs
          z @$spinner, {hasTopMargin: false}
        else
          _map gifs, (gif) =>
            fixedHeightImg = gif.images.fixed_height
            height = 100
            width = fixedHeightImg.width / fixedHeightImg.height * height
            z 'img.gif', {
              width: width
              height: height
              onclick: =>
                @message.next "![](<#{gif.images.fixed_height.url} " +
                              "=#{width}x#{height}>)"
                @onPost()
                .then =>
                  @currentPanel.next 'text'
              src: if supportsWebP \
                   then gif.images.fixed_height.webp
                   else gif.images.fixed_height.url
            }
