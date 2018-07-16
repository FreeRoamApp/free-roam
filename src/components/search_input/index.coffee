z = require 'zorium'

colors = require '../../colors'

if window?
  require './index.styl'

Icon = require '../icon'

module.exports = class SearchInput
  constructor: ({@model, @searchValue, @router}) ->
    @$backIcon = new Icon()
    @$clearIcon = new Icon()

    @state = z.state
      _isFocused: false
      searchValue: @searchValue

  afterMount: (@$$el) => null

  open: =>
    @state.set _isFocused: true

  close: =>
    @state.set _isFocused: false

  clear: =>
    @searchValue.next ''

  render: (options = {}) =>
    {placeholder, isFocused, onBack, height, bgColor,
      alwaysShowBack, isSearchIconRight, onclick} = options

    {_isFocused, searchValue} = @state.getValue()

    onBack ?= =>
      @router.back()
    height ?= '56px'
    isFocused ?= _isFocused
    bgColor ?= colors.$tertiary700
    placeholder ?= @model.l.get 'searchInput.placeholder'
    hasOnClick = Boolean onclick

    z '.z-search-input', {
      className: z.classKebab {isFocused, isSearchIconRight, hasOnClick}
      onclick: (e) ->
        if onclick
          e?.preventDefault()
          onclick?()
    },
      z '.search-overlay', {
        style:
          height: height
      },
        unless isSearchIconRight
          z 'span.left-icon',
            z @$backIcon,
              icon: if isFocused or alwaysShowBack then 'back' else 'search'
              color: if isFocused or alwaysShowBack \
                     then colors.$primary900
                     else colors.$grey400
              onclick: =>
                onBack?()
                @clear()
                @close()
                @$$el?.querySelector('.input').blur()
        z 'span.right-icon',
          if searchValue or isSearchIconRight
            z @$clearIcon,
              icon: if isSearchIconRight and not searchValue \
                    then 'search'
                    else 'close'
              color: if isSearchIconRight and not searchValue \
                     then colors.$tertiary900Text54
                     else colors.$tertiary900Text
              touchHeight: height
              onclick: @clear
      z 'form.form', {
        onsubmit: (e) ->
          e.preventDefault()
          document.activeElement.blur() # hide keyboard
        style:
          height: height
      },
        z 'input.input',
          placeholder: placeholder
          value: searchValue
          onfocus: @open
          onblur: @close
          focused: 'focused'
          style:
            backgroundColor: bgColor
          oninput: z.ev (e, $$el) =>
            @searchValue.next $$el?.value
