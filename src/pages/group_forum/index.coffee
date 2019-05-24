z = require 'zorium'
RxBehaviorSubject = require('rxjs/BehaviorSubject').BehaviorSubject

AppBar = require '../../components/app_bar'
ButtonMenu = require '../../components/button_menu'
Threads = require '../../components/threads'
FilterThreadsDialog = require '../../components/filter_threads_dialog'
Icon = require '../../components/icon'
Fab = require '../../components/fab'
colors = require '../../colors'
config = require '../../config'

if window?
  require './index.styl'

module.exports = class GroupForumPage
  isGroup: true
  @hasBottomBar: true
  constructor: ({@model, requests, @router, serverData, group, @$bottomBar}) ->
    @isFilterThreadsDialogVisible = new RxBehaviorSubject false
    filter = new RxBehaviorSubject {
      sort: 'popular'
      filter: 'all'
    }

    @$appBar = new AppBar {@model}
    @$buttonMenu = new ButtonMenu {@model}
    @$fab = new Fab()
    @$addIcon = new Icon()
    @$filterIcon = new Icon()
    @$filterThreadsDialog = new FilterThreadsDialog {
      @model, filter, group, isVisible: @isFilterThreadsDialogVisible
    }

    @$threads = new Threads {@model, @router, filter, group}

    @state = z.state
      isFilterThreadsDialogVisible: @isFilterThreadsDialogVisible
      group: group

  getMeta: =>
    {
      title: @model.l.get 'general.forum'
      description: @model.l.get 'groupForumPage.description'
    }

  render: =>
    {isFilterThreadsDialogVisible, group} = @state.getValue()

    z '.p-group-forum',
      z @$appBar, {
        title: @model.l.get 'general.forum'
        $topLeftButton: z @$buttonMenu, {color: colors.$header500Icon}
        $topRightButton:
          z @$filterIcon,
            color: colors.$header500Icon
            icon: 'filter'
            hasRipple: true
            onclick: =>
              @isFilterThreadsDialogVisible.next true
      }
      @$threads
      @$bottomBar

      if isFilterThreadsDialogVisible
        z @$filterThreadsDialog

      z '.fab',
        z @$fab,
          isPrimary: true
          icon: 'add'
          onclick: =>
            @model.group.goPath group, 'groupNewThread', {@router}
