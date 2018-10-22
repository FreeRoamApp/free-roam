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
AddToHomeScreenSheet = require './components/add_to_home_sheet'
WelcomeDialog = require './components/welcome_dialog'
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
  EditProfilePage: require './pages/edit_profile'
  EditReviewPage: require './pages/edit_review'
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
  NewAmenityPage: require './pages/new_amenity'
  NewCampgroundPage: require './pages/new_campground'
  NewReviewPage: require './pages/new_review'
  NewThreadPage: require './pages/new_thread'
  PartnersPage: require './pages/partners'
  PlacePage: require './pages/place'
  PlaceAttachmentsPage: require './pages/place_attachments'
  PlacesPage: require './pages/places'
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

    requestsAndRoutes = RxObservable.combineLatest(
      requests, routes, (vals...) -> vals
    )

    isFirstRequest = true
    @requests = requestsAndRoutes.map ([req, routes]) =>
      if window? and isFirstRequest and req.query.partner
        @model.user.setPartner req.query.partner

      if isFirstRequest and isNativeApp
        path = @model.cookie.get('routerLastPath') or req.path
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

    # used for overlay pages
    @router.setRequests @requests

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

    @$offlineOverlay = new OfflineOverlay {@model, isOffline}
    @$navDrawer = new NavDrawer {@model, @router, @group}
    @$addToHomeSheet = new AddToHomeScreenSheet {
      @model
      @router
    }
    @$bottomBar = new BottomBar {
      @model, @router, @requests, @group, @serverData
    }
    @$head = new Head({
      @model
      @requests
      @serverData
      @group
    })

    @$nps = new Nps {@model}

    me = @model.user.getMe()

    if window? and not @model.cookie.get 'lastAddToHomePromptTime'
      setTimeout =>
        isNative = Environment.isNativeApp('freeroam')
        if not isNative and not @model.cookie.get('lastAddToHomePromptTime') and false # FIXME TODO
          @model.overlay.open @$addToHomeSheet
          @model.cookie.set 'lastAddToHomePromptTime', Date.now()
      , TIME_UNTIL_ADD_TO_HOME_PROMPT_MS

    if window? and not @model.cookie.get 'hasSeenWelcome'
      @model.cookie.set 'hasSeenWelcome', 1
      @model.overlay.open new WelcomeDialog {@model, @router}

    @state = z.state {
      $backupPage: $backupPage
      me: me
      $overlays: @model.overlay.get$()
      isOffline: isOffline
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
        _values @model.l.getAllPathsByRouteKey routeKey

      _map paths, (path) =>
        routes.set path, =>
          unless @$cachedPages[pageKey]
            @$cachedPages[pageKey] = new Page({
              @model
              @router
              @serverData
              @group
              $bottomBar: if Page.hasBottomBar then @$bottomBar
              requests: @requests.filter ({$page}) ->
                $page instanceof Page
            })
          return @$cachedPages[pageKey]

    userAgent = @model.window.getUserAgent()
    isiOSApp = Environment.isiOS({userAgent}) and
                Environment.isNativeApp('freeroam', {userAgent})
    route 'about', 'AboutPage'
    route ['campgroundAttachments'], 'PlaceAttachmentsPage'
    route ['amenity', 'campground', 'campgroundWithTab'], 'PlacePage'
    route 'backpack', 'BackpackPage'
    route ['campgroundNewReview'], 'NewReviewPage'
    route ['campgroundEditReview'], 'EditReviewPage'
    route 'categories', 'CategoriesPage'
    route 'conversation', 'ConversationPage'
    route 'conversations', 'ConversationsPage'
    route 'editProfile', 'EditProfilePage'
    route 'groupAdminBannedUsers', 'GroupBannedUsersPage'
    route 'groupAdminAuditLog', 'GroupAuditLogPage'
    route ['groupChat', 'groupChatConversation'], 'GroupChatPage'
    route 'groupAdminEditChannel', 'GroupEditChannelPage'
    route 'groupForum', 'GroupForumPage'
    route 'groupAdminManage', 'GroupManageMemberPage'
    route 'groupAdminManageChannels', 'GroupManageChannelsPage'
    route 'groupAdminManageRoles', 'GroupManageRolesPage'
    route 'groupAdminNewChannel', 'GroupAddChannelPage'
    route ['groupNewThread', 'groupNewThreadWithCategory'], 'NewThreadPage'
    route 'groupAdminSettings', 'GroupSettingsPage'
    route 'groupThread', 'ThreadPage'
    route 'groupThreadEdit', 'EditThreadPage'
    route 'item', 'ItemPage'
    route ['itemsByCategory', 'itemsBySearch'], 'ItemsPage'
    route 'newAmenity', 'NewAmenityPage'
    route 'newCampground', 'NewCampgroundPage'
    route 'partners', 'PartnersPage'
    route ['places', 'home'], 'PlacesPage'
    route 'product', 'ProductPage'
    route 'policies', 'PoliciesPage'
    route 'termsOfService', 'TosPage'
    route 'privacy', 'PrivacyPage'

    route '404', 'FourOhFourPage'
    routes

  render: =>
    {request, $backupPage, me, hideDrawer,
      $overlays, isOffline} = @state.getValue()

    userAgent = @model.window.getUserAgent()
    isIos = Environment.isiOS {userAgent}
    isAndroid = Environment.isAndroid {userAgent}
    isNative = Environment.isNativeApp 'freeroam', {userAgent}

    if @router.preservedRequest
      $page = @router.preservedRequest?.$page
      $overlayPage = request?.$page
    else
      $page = request?.$page or $backupPage

    z 'html',
      z @$head, {meta: $page?.getMeta?()}
      z 'body',
        z '#zorium-root', {
          className: z.classKebab {isIos, isAndroid}
        },
          z '.z-root',
            unless hideDrawer
              z @$navDrawer, {currentPath: request?.req.path}

            z '.page', {key: 'page'},
              $page

            if isOffline
              z @$offlineOverlay
            if @$nps.shouldBeShown()
              z @$nps,
                gameName: 'free-roam'
                onRate: =>
                  @model.portal.call 'app.rate'

            if $overlayPage
              z '.overlay-page', {key: 'overlay-page'},
                z $overlayPage

            _map $overlays, ($overlay) ->
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
