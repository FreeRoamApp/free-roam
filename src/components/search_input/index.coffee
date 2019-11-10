z = require 'zorium'
RxBehaviorSubject = require('rxjs/BehaviorSubject').BehaviorSubject
RxObservable = require('rxjs/Observable').Observable
require 'rxjs/add/observable/of'

colors = require '../../colors'

if window?
  require './index.styl'

ButtonMenu = require '../button_menu'
Icon = require '../icon'

module.exports = class SearchInput
  constructor: (options) ->
    {@model, @searchValue, @searchValueStreams, @router,
      @isFocused, @onFocus} = options
    @$backIcon = new Icon()
    @$clearIcon = new Icon()
    @$buttonMenu = new ButtonMenu {@model, @router}

    @isFocused ?= new RxBehaviorSubject false

    @state = z.state
      isFocused: @isFocused
      searchValue: @searchValueStreams?.switch() or @searchValue

  afterMount: (@$$el) => null

  open: =>
    @onFocus?()
    @isFocused.next true

  close: =>
    @isFocused.next false

  clear: =>
    if @searchValueStreams
      @searchValueStreams.next RxObservable.of ''
    else
      @searchValue.next ''

  render: (options = {}) =>
    {$topLeftButton, $topRightButton, placeholder, onBack, height, bgColor,
      clearOnBack, isAppBar, alwaysShowBack
      isSearchOnSubmit, onclick, onsubmit, onfocus, onblur
      ontouchstart} = options

    {isFocused, searchValue} = @state.getValue()

    onBack ?= =>
      @router.back()
    clearOnBack ?= true
    height ?= '48px'
    bgColor ?= colors.$tertiary0
    placeholder ?= @model.l.get 'searchInput.placeholder'

    z '.z-search-input', {
      className: z.classKebab {
        isFocused, isSearchOnSubmit, isServerSide: not window?
      }
      onclick: (e) ->
        if onclick
          e?.preventDefault()
          onclick?()
    },
      z '.search-overlay', {
        style:
          height: height
      },
        unless isSearchOnSubmit
          z '.left-icon',
            if isAppBar and @$buttonMenu.isVisible() and not alwaysShowBack
              z @$buttonMenu, {
                isAlignedLeft: false
              }
            else
              z @$backIcon,
                icon: if isFocused or alwaysShowBack then 'back' else 'search'
                color: if isFocused or alwaysShowBack \
                       then colors.$bgText70
                       else colors.$bgText26
                onclick: (e) =>
                  onBack? e
                  if clearOnBack
                    @clear()
                  @close()
                  @$$el?.querySelector('.input').blur()
        z '.right-icon',
          if $topRightButton
            $topRightButton
          else if (searchValue or isSearchOnSubmit) and not isAppBar
            z @$clearIcon,
              icon: 'search'
              color: if isSearchOnSubmit and not searchValue \
                     then colors.$bgText54
                     else colors.$bgText
              touchHeight: height
              onclick: ->
                onsubmit?()
      z 'form.form', {
        onsubmit: (e) ->
          e.preventDefault()
          onsubmit?()
          document.activeElement.blur() # hide keyboard
        style:
          height: height
      },
        z 'input.input',
          type: 'text'
          placeholder: placeholder
          value: if window? then searchValue
          onfocus: (e) =>
            @open e
            onfocus? e
          onblur: (e) =>
            @close e
            onblur? e
          ontouchstart: (e) ->
            ontouchstart? e
          style:
            backgroundColor: bgColor
          oninput: (e) =>
            if @searchValueStreams
              @searchValueStreams.next RxObservable.of e.target.value
            else
              @searchValue.next e.target.value
