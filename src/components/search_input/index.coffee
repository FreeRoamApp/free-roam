z = require 'zorium'
RxBehaviorSubject = require('rxjs/BehaviorSubject').BehaviorSubject

colors = require '../../colors'

if window?
  require './index.styl'

ButtonMenu = require '../button_menu'
Icon = require '../icon'

module.exports = class SearchInput
  constructor: ({@model, @searchValue, @router, @isFocused}) ->
    @$backIcon = new Icon()
    @$clearIcon = new Icon()
    @$buttonMenu = new ButtonMenu {@model, @router}

    @isFocused ?= new RxBehaviorSubject false

    @state = z.state
      isFocused: @isFocused
      searchValue: @searchValue

  afterMount: (@$$el) => null

  open: =>
    @isFocused.next true

  close: =>
    @isFocused.next false

  clear: =>
    @searchValue.next ''

  render: (options = {}) =>
    {placeholder, onBack, height, bgColor, clearOnBack, isAppBar, alwaysShowBack
      isSearchOnSubmit, onclick, onsubmit, onfocus, onblur
      ontouchstart} = options

    {isFocused, searchValue} = @state.getValue()

    onBack ?= =>
      @router.back()
    clearOnBack ?= true
    height ?= '36px'
    bgColor ?= colors.$tertiary100
    placeholder ?= @model.l.get 'searchInput.placeholder'

    z '.z-search-input', {
      className: z.classKebab {isFocused, isSearchOnSubmit}
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
              z @$buttonMenu, {isAlignedLeft: false}
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
          if (searchValue or isSearchOnSubmit) and not isAppBar
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
            @searchValue.next e.target.value
