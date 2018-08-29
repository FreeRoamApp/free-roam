z = require 'zorium'
HttpHash = require 'http-hash'
_forEach = require 'lodash/forEach'
_map = require 'lodash/map'
_values = require 'lodash/values'
_flatten = require 'lodash/flatten'
_defaults = require 'lodash/defaults'
isUuid = require 'isuuid'
RxObservable = require('rxjs/Observable').Observable
RxBehaviorSubject = require('rxjs/BehaviorSubject').BehaviorSubject
require 'rxjs/add/operator/map'
require 'rxjs/add/operator/filter'
require 'rxjs/add/operator/switchMap'
require 'rxjs/add/observable/combineLatest'
require 'rxjs/add/observable/of'
require 'rxjs/add/operator/publishReplay'

Head = require './components/head'
NavDrawer = require './components/nav_drawer'
BottomBar = require './components/bottom_bar'
SignInDialog = require './components/sign_in_dialog'
InstallOverlay = require './components/install_overlay'
GetAppDialog = require './components/get_app_dialog'
AddToHomeScreenSheet = require './components/add_to_home_sheet'
PushNotificationsSheet = require './components/push_notifications_sheet'
# ConversationImageView = require './components/conversation_image_view'
OfflineOverlay = require './components/offline_overlay'
Nps = require './components/nps'
Environment = require './services/environment'
config = require './config'
colors = require './colors'

Pages =
  AboutPage: require './pages/about'
  BackpackPage: require './pages/backpack'
  CategoriesPage: require './pages/categories'
  ConversationPage: require './pages/conversation'
  ConversationsPage: require './pages/conversations'
  EditThreadPage: require './pages/edit_thread'
  GroupAddChannelPage: require './pages/group_add_channel'
  GroupAuditLogPage: require './pages/group_audit_log'
  GroupBannedUsersPage: require './pages/group_banned_users'
  GroupChatPage: require './pages/group_chat'
  GroupEditChannelPage: require './pages/group_edit_channel'
  GroupForumPage: require './pages/group_forum'
  GroupManageChannelsPage: require './pages/group_manage_channels'
  GroupManageRolesPage: require './pages/group_manage_roles'
  GroupManageMemberPage: require './pages/group_manage_member'
  GroupSettingsPage: require './pages/group_settings'
  HomePage: require './pages/home'
  ItemPage: require './pages/item'
  ItemsPage: require './pages/items'
  PlacesPage: require './pages/places'
  NewThreadPage: require './pages/new_thread'
  PartnersPage: require './pages/partners'
  ProductPage: require './pages/product'
  PoliciesPage: require './pages/policies'
  PrivacyPage: require './pages/privacy'
  ThreadPage: require './pages/thread'
  TosPage: require './pages/tos'
  FourOhFourPage: require './pages/404'

TIME_UNTIL_ADD_TO_HOME_PROMPT_MS = 90000 # 1.5 min

module.exports = class App
  constructor: (options) ->
    {requests, @serverData, @model, @router, isOffline, @isCrawler} = options
    @$cachedPages = []
    routes = @model.window.getBreakpoint().map @getRoutes
            .publishReplay(1).refCount()

    userAgent = @model.window.getUserAgent()
    isNativeApp = Environment.isMainApp 'freeroam', {userAgent}
    if isNativeApp and not @model.cookie.get('routerLastPath')
      appActionPath = @model.appInstallAction.get().map (appAction) ->
        appAction?.path
    else
      appActionPath = RxObservable.of null

    requestsAndRoutes = RxObservable.combineLatest(
      requests, routes, appActionPath, (vals...) -> vals
    )

    isFirstRequest = true
    @requests = requestsAndRoutes.map ([req, routes, appActionPath]) =>
      if isFirstRequest and isNativeApp
        path = @model.cookie.get('routerLastPath') or appActionPath or req.path
        if window?
          req.path = path # doesn't work server-side
        else
          req = _defaults {path}, req

      subdomain = @router.getSubdomain()

      if subdomain # equiv to /groupId/route
        route = routes.get "/#{subdomain}#{req.path}"
        if route.handler?() instanceof Pages['FourOhFourPage']
          route = routes.get req.path
      else
        route = routes.get req.path

      $page = route.handler?()
      isFirstRequest = false
      {req, route, $page: $page}
    .publishReplay(1).refCount()

    @group = @requests.switchMap ({route}) =>
      host = @serverData?.req?.headers.host or window?.location?.host
      groupId = route.params.groupId

      subdomain = @router.getSubdomain()
      if subdomain and not groupId
        groupId = subdomain

      groupId or= @model.cookie.get 'lastGroupId'

      (if isUuid groupId
        @model.group.getById groupId, {autoJoin: true}
      else if groupId and groupId isnt 'undefined' and groupId isnt 'null'
        @model.group.getBySlug groupId, {autoJoin: true}
      else
        @model.group.getDefaultGroup {autoJoin: true}
      )
    .publishReplay(1).refCount()

    isNativeApp = Environment.isNativeApp 'freeroam', {userAgent}

    # used if state / requests fails to work
    $backupPage = if @serverData?
      if isNativeApp
        serverPath = @model.cookie.get('routerLastPath') or @serverData.req.path
      else
        serverPath = @serverData.req.path
      @getRoutes().get(serverPath).handler?()
    else
      null

    addToHomeSheetIsVisible = new RxBehaviorSubject false

    # TODO: have all other component overlays use this
    @overlay$ = new RxBehaviorSubject null

    @$offlineOverlay = new OfflineOverlay {@model, isOffline}
    @$navDrawer = new NavDrawer {@model, @router, @group, @overlay$}
    @$signInDialog = new SignInDialog {@model, @router, @group}
    @$getAppDialog = new GetAppDialog {@model, @router, @group}
    @$installOverlay = new InstallOverlay {@model, @router}
    @$addToHomeSheet = new AddToHomeScreenSheet {
      @model
      @router
      isVisible: addToHomeSheetIsVisible
    }
    @$pushNotificationsSheet = new PushNotificationsSheet {@model, @router}
    @$bottomBar = new BottomBar {@model, @router, @requests, @group, @serverData}
    @$head = new Head({
      @model
      @requests
      @serverData
      @group
    })

    @$nps = new Nps {@model}

    me = @model.user.getMe()

    if localStorage? and not localStorage['lastAddToHomePromptTime']
      setTimeout ->
        isNative = Environment.isNativeApp('freeroam')
        if not isNative and not localStorage['lastAddToHomePromptTime'] and false # FIXME TODO
          addToHomeSheetIsVisible.next true
          localStorage['lastAddToHomePromptTime'] = Date.now()
      , TIME_UNTIL_ADD_TO_HOME_PROMPT_MS

    @state = z.state {
      $backupPage: $backupPage
      me: me
      $overlay: @overlay$
      isOffline: isOffline
      addToHomeSheetIsVisible: addToHomeSheetIsVisible
      signInDialogIsOpen: @model.signInDialog.isOpen()
      signInDialogMode: @model.signInDialog.getMode()
      getAppDialogIsOpen: @model.getAppDialog.isOpen()
      pushNotificationSheetIsOpen: @model.pushNotificationSheet.isOpen()
      installOverlayIsOpen: @model.installOverlay.isOpen()
      hideDrawer: @requests.switchMap (request) ->
        hideDrawer = request.$page?.hideDrawer
        if hideDrawer?.map
        then hideDrawer
        else RxObservable.of (hideDrawer or false)
      request: @requests.do ({$page, req}) ->
        if $page instanceof Pages['FourOhFourPage']
          res?.status? 404
    }

  getRoutes: (breakpoint) =>
    # can have breakpoint (mobile/desktop) specific routes
    routes = new HttpHash()
    languages = @model.l.getAllUrlLanguages()

    route = (routeKeys, pageKey) =>
      Page = Pages[pageKey]
      if typeof routeKeys is 'string'
        routeKeys = [routeKeys]

      paths = _flatten _map routeKeys, (routeKey) =>
        # if routeKey is '404'
        #   return _map languages, (lang) ->
        #     if lang is 'en' then '/:gameKey/*' else "/#{lang}/:gameKey/*"
        _values @model.l.getAllPathsByRouteKey routeKey

      _map paths, (path) =>
        routes.set path, =>
          unless @$cachedPages[pageKey]
            @$cachedPages[pageKey] = new Page({
              @model
              @router
              @serverData
              @overlay$
              @group
              $bottomBar: if Page.hasBottomBar then @$bottomBar
              requests: @requests.filter ({$page}) ->
                $page instanceof Page
            })
          return @$cachedPages[pageKey]

    userAgent = @model.window.getUserAgent()
    isiOSApp = Environment.isiOS({userAgent}) and
                Environment.isNativeApp('freeroam', {userAgent})
    isSafari = /^((?!chrome|android).)*safari/i.test(userAgent)
    disableWeb = isSafari and not isiOSApp
    if disableWeb
      route ['about', '404', 'home'], 'AboutPage'
      route 'termsOfService', 'TosPage'
      route 'privacy', 'PrivacyPage'
    else
      route 'about', 'AboutPage'
      route 'backpack', 'BackpackPage'
      route 'categories', 'CategoriesPage'
      route 'conversation', 'ConversationPage'
      route 'conversations', 'ConversationsPage'
      route 'groupBannedUsers', 'GroupBannedUsersPage'
      route 'groupAuditLog', 'GroupAuditLogPage'
      route ['groupChat', 'groupChatConversation'], 'GroupChatPage'
      route 'groupEditChannel', 'GroupEditChannelPage'
      route 'groupForum', 'GroupForumPage'
      route 'groupManage', 'GroupManageMemberPage'
      route 'groupManageChannels', 'GroupManageChannelsPage'
      route 'groupManageRoles', 'GroupManageRolesPage'
      route 'groupNewChannel', 'GroupAddChannelPage'
      route ['groupNewThread', 'groupNewThreadWithCategory'], 'NewThreadPage'
      route 'groupSettings', 'GroupSettingsPage'
      route 'groupThread', 'ThreadPage'
      route 'groupThreadEdit', 'EditThreadPage'
      route 'home', if isiOSApp then 'GroupForumPage' else 'CategoriesPage'
      route 'item', 'ItemPage'
      route ['itemsByCategory', 'itemsBySearch'], 'ItemsPage'
      route 'places', 'PlacesPage'
      route 'partners', 'PartnersPage'
      route 'product', 'ProductPage'

      route 'policies', 'PoliciesPage'
      route 'termsOfService', 'TosPage'
      route 'privacy', 'PrivacyPage'

      route '404', 'FourOhFourPage'
    routes

  render: =>
    {request, $backupPage, $modal, me, hideDrawer
      installOverlayIsOpen, signInDialogIsOpen, signInDialogMode,
      pushNotificationSheetIsOpen, getAppDialogIsOpen
      addToHomeSheetIsVisible, $overlay, isOffline} = @state.getValue()

    userAgent = @model.window.getUserAgent()
    isIos = Environment.isiOS {userAgent}
    isSafari = /^((?!chrome|android).)*safari/i.test(userAgent)
    isAndroid = Environment.isAndroid {userAgent}
    isNative = Environment.isNativeApp 'freeroam', {userAgent}
    isPageAvailable = (me?.username or not request?.$page?.isPrivate)
    defaultInstallMessage = @model.l.get 'app.defaultInstallMessage'

    $page = request?.$page or $backupPage

    z 'html',
      z @$head, {meta: $page?.getMeta?()}
      z 'body',
        z '#zorium-root', {
          className: z.classKebab {isIos, isAndroid}
        },
          z '.z-root',
            if not hideDrawer and (not isSafari or isNative)
              z @$navDrawer, {currentPath: request?.req.path}
            z '.page',
              # show page before me has loaded
              if (not me or isPageAvailable) and request?.$page
                request.$page
              else
                $backupPage

            if signInDialogIsOpen
              z @$signInDialog, {mode: signInDialogMode}
            if getAppDialogIsOpen
              z @$getAppDialog
            if installOverlayIsOpen
              z @$installOverlay
            if addToHomeSheetIsVisible
              z @$addToHomeSheet, {
                message: request?.$page?.installMessage or defaultInstallMessage
              }
            if pushNotificationSheetIsOpen
              z @$pushNotificationsSheet
            if isOffline
              z @$offlineOverlay
            if @$nps.shouldBeShown()
              z @$nps,
                gameName: 'free-roam'
                onRate: =>
                  @model.portal.call 'app.rate'
            if $overlay
              # can be array of components or component
              z $overlay
            # if not window?
            #   z '#server-loading', {
            #     key: 'server-loading'
            #     attributes:
            #       onmousedown: "document.getElementById('server-loading')" +
            #         ".classList.add('is-clicked')"
            #       ontouchstart: "document.getElementById('server-loading')" +
            #         ".classList.add('is-clicked')"
            #
            #   },
            #     @model.l.get 'app.stillLoading'
            # used in color.coffee to detect support
            z '#css-variable-test',
              style:
                display: 'none'
                backgroundColor: 'var(--test-color)'
