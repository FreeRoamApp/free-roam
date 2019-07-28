z = require 'zorium'
HttpHash = require 'http-hash'
_forEach = require 'lodash/forEach'
_map = require 'lodash/map'
_values = require 'lodash/values'
_flatten = require 'lodash/flatten'
_isEmpty = require 'lodash/isEmpty'
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
StatusBar = require './components/status_bar'
SnackBar = require './components/snack_bar'
Environment = require './services/environment'
config = require './config'
colors = require './colors'

Pages =
  AboutPage: require './pages/about'
  AmenityPage: require './pages/amenity'
  AmenityAttachmentsPage: require './pages/amenity_attachments'
  CampgroundPage: require './pages/campground'
  CampgroundAttachmentsPage: require './pages/campground_attachments'
  CheckInPage: require './pages/check_in'
  ConversationPage: require './pages/conversation'
  ConversationsPage: require './pages/conversations'
  DashboardPage: require './pages/dashboard'
  DonatePage: require './pages/donate'
  EditProfilePage: require './pages/edit_profile'
  EditAmenityPage: require './pages/edit_amenity'
  EditCampgroundPage: require './pages/edit_campground'
  EditCheckInPage: require './pages/edit_check_in'
  EditOvernightPage: require './pages/edit_overnight'
  EditAmenityReviewPage: require './pages/edit_amenity_review'
  EditCampgroundReviewPage: require './pages/edit_campground_review'
  EditOvernightReviewPage: require './pages/edit_overnight_review'
  EditThreadPage: require './pages/edit_thread'
  EventPage: require './pages/event'
  EventsPage: require './pages/events'
  TripPage: require './pages/trip'
  GroupAddChannelPage: require './pages/group_add_channel'
  GroupAuditLogPage: require './pages/group_audit_log'
  GroupBannedUsersPage: require './pages/group_banned_users'
  GroupChatPage: require './pages/group_chat'
  GroupEditChannelPage: require './pages/group_edit_channel'
  GroupForumPage: require './pages/group_forum'
  GroupInfoPage: require './pages/group_info'
  GroupManageChannelsPage: require './pages/group_manage_channels'
  GroupManageRolesPage: require './pages/group_manage_roles'
  GroupManageMemberPage: require './pages/group_manage_member'
  GroupSettingsPage: require './pages/group_settings'
  GuidesPage: require './pages/guides'
  HomePage: require './pages/home'
  ItemPage: require './pages/item'
  ItemsPage: require './pages/items'
  LoginLinkPage: require './pages/login_link'
  MyPlacesPage: require './pages/my_places'
  NewAmenityPage: require './pages/new_amenity'
  NewAmenityReviewPage: require './pages/new_amenity_review'
  NewCampgroundPage: require './pages/new_campground'
  NewCampgroundReviewPage: require './pages/new_campground_review'
  NewCheckInPage: require './pages/new_check_in'
  NewMvumPage: require './pages/new_mvum'
  NewOvernightPage: require './pages/new_overnight'
  NewOvernightReviewPage: require './pages/new_overnight_review'
  NewThreadPage: require './pages/new_thread'
  NotificationsPage: require './pages/notifications'
  OvernightPage: require './pages/overnight'
  OvernightAttachmentsPage: require './pages/overnight_attachments'
  PlacesPage: require './pages/places'
  PreservationPage: require './pages/preservation'
  ProductPage: require './pages/product'
  ProductGuidesPage: require './pages/product_guides'
  ProfilePage: require './pages/profile'
  ProfileAttachmentsPage: require './pages/profile_attachments'
  ProfileFriendsPage: require './pages/profile_friends'
  ProfileReviewsPage: require './pages/profile_reviews'
  PoliciesPage: require './pages/policies'
  PrivacyPage: require './pages/privacy'
  SettingsPage: require './pages/settings'
  ShellPage: require './pages/shell'
  SocialPage: require './pages/social'
  ThreadPage: require './pages/thread'
  TravelMapScreenshotPage: require './pages/travel_map_screenshot'
  TosPage: require './pages/tos'
  TransactionsPage: require './pages/transactions'
  TripPage: require './pages/trip'
  FourOhFourPage: require './pages/404'

TIME_UNTIL_ADD_TO_HOME_PROMPT_MS = 90000 # 1.5 min

module.exports = class App
  constructor: (options) ->
    {requests, @serverData, @model, @router, @isCrawler} = options
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
      if subdomain and subdomain isnt 'staging' and not groupId
        groupId = subdomain

      groupId or= @model.cookie.get 'lastGroupId'

      (if isUuid groupId
        @model.group.getById groupId, {autoJoin: false}
      else if groupId and groupId isnt 'undefined' and groupId isnt 'null'
        @model.group.getBySlug groupId, {autoJoin: false}
      else
        @model.group.getDefaultGroup {autoJoin: false}
      )
    .publishReplay(1).refCount()

    isNativeApp = Environment.isNativeApp 'freeroam', {userAgent}

    @$navDrawer = new NavDrawer {@model, @router, @group}
    @$statusBar = new StatusBar {@model}
    @$snackBar = new SnackBar {@model}
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

    me = @model.user.getMe()

    if window? and not @model.cookie.get 'lastAddToHomePromptTime'
      setTimeout =>
        isNative = Environment.isNativeApp('freeroam')
        if not isNative and not @model.cookie.get('lastAddToHomePromptTime') and false # FIXME TODO
          @model.overlay.open @$addToHomeSheet
          @model.cookie.set 'lastAddToHomePromptTime', Date.now()
      , TIME_UNTIL_ADD_TO_HOME_PROMPT_MS

    if (window? and not @model.cookie.get 'hasSeenWelcome')
      @model.cookie.set 'hasSeenWelcome', 1
      @model.overlay.open new WelcomeDialog {@model, @router}

    # used if state / requests fails to work
    $backupPage = if @serverData?
      if isNativeApp
        serverPath = @model.cookie.get('routerLastPath') or @serverData.req.path
      else
        serverPath = @serverData.req.path
      @getRoutes().get(serverPath).handler?()
    else
      null

    $backupPage or= new Pages.FourOhFourPage {
      @model, @router, @serverData
    }

    @state = z.state {
      $backupPage: $backupPage
      me: me
      $overlays: @model.overlay.get$()
      $tooltip: @model.tooltip.get$()
      statusBarData: @model.statusBar.getData()
      windowSize: @model.window.getSize()
      hideDrawer: @requests.switchMap (request) =>
        $page = @router.preservedRequest?.$page or request.$page
        hideDrawer = $page?.hideDrawer
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
    isIosApp = Environment.isIos({userAgent}) and
                Environment.isNativeApp('freeroam', {userAgent})
    route 'about', 'AboutPage'
    route ['amenity', 'amenityWithTab'], 'AmenityPage'
    route 'amenityAttachments', 'AmenityAttachmentsPage'
    route ['campground', 'campgroundWithTab'], 'CampgroundPage'
    route 'campgroundAttachments', 'CampgroundAttachmentsPage'
    route 'checkIn', 'CheckInPage'
    route 'conversation', 'ConversationPage'
    route 'conversations', 'ConversationsPage'
    route 'dashboard', 'DashboardPage'
    route 'donate', 'DonatePage'
    route 'editAmenity', 'EditAmenityPage'
    route 'editAmenityReview', 'EditAmenityReviewPage'
    route 'editCampground', 'EditCampgroundPage'
    route 'editCampgroundReview', 'EditCampgroundReviewPage'
    route 'editCheckIn', 'EditCheckInPage'
    route 'editOvernight', 'EditOvernightPage'
    route 'editOvernightReview', 'EditOvernightReviewPage'
    route 'editProfile', 'EditProfilePage'
    route 'event', 'EventPage'
    route 'events', 'EventsPage'
    route 'groupAdminBannedUsers', 'GroupBannedUsersPage'
    route 'groupAdminAuditLog', 'GroupAuditLogPage'
    route ['group', 'groupIfno'], 'GroupInfoPage'
    route ['groupChat', 'groupChatConversation'], 'GroupChatPage'
    route 'groupAdminEditChannel', 'GroupEditChannelPage'
    route 'groupForum', 'GroupForumPage'
    route 'groupAdminManage', 'GroupManageMemberPage'
    route 'groupAdminManageChannels', 'GroupManageChannelsPage'
    route 'groupAdminManageRoles', 'GroupManageRolesPage'
    route 'groupAdminNewChannel', 'GroupAddChannelPage'
    route ['groupNewThread', 'groupNewThreadWithCategory'], 'NewThreadPage'
    route 'groupAdminSettings', 'GroupSettingsPage'
    route ['groupThread', 'guide'], 'ThreadPage'
    route 'groupThreadEdit', 'EditThreadPage'
    route 'guides', 'GuidesPage'
    route 'item', 'ItemPage'
    route ['itemsByCategory', 'itemsBySearch'], 'ItemsPage'
    route 'loginLink', 'LoginLinkPage'
    route 'myPlaces', 'MyPlacesPage'
    route 'newAmenity', 'NewAmenityPage'
    route 'newAmenityReview', 'NewAmenityReviewPage'
    route 'newCampground', 'NewCampgroundPage'
    route 'newCampgroundReview', 'NewCampgroundReviewPage'
    route 'newCheckIn', 'NewCheckInPage'
    route 'newMvum', 'NewMvumPage'
    route 'newOvernight', 'NewOvernightPage'
    route 'newOvernightReview', 'NewOvernightReviewPage'
    route 'notifications', 'NotificationsPage'
    route ['overnight', 'overnightWithTab'], 'OvernightPage'
    route 'overnightAttachments', 'OvernightAttachmentsPage'
    route [
      'places', 'home', 'placesWithType', 'placesWithTypeAndSubType'
      'placesWithLocation', 'placesWithLocationAndType'
      'placesWithLocationAndTypeAndSubType'
    ], 'PlacesPage'
    route ['preservation', 'roamWithCare'], 'PreservationPage'
    route 'product', 'ProductPage'
    route 'productGuides', 'ProductGuidesPage'
    route ['profile', 'profileMe', 'profileById'], 'ProfilePage'
    route ['profileAttachments', 'profileAttachmentsById'], 'ProfileAttachmentsPage'
    route ['profileFriends', 'profileFriendsById'], 'ProfileFriendsPage'
    route ['profileReviews', 'profileReviewsById'], 'ProfileReviewsPage'
    route 'policies', 'PoliciesPage'
    route 'privacy', 'PrivacyPage'
    route 'settings', 'SettingsPage'
    route 'shell', 'ShellPage'
    route 'social', 'SocialPage'
    route 'termsOfService', 'TosPage'
    route 'transactions', 'TransactionsPage'
    route 'travelMapScreenshot', 'TravelMapScreenshotPage'
    route ['trip', 'tripByType'], 'TripPage'

    route '404', 'FourOhFourPage'
    routes

  render: =>
    {request, $backupPage, me, hideDrawer, statusBarData, windowSize,
      $overlays, $tooltip} = @state.getValue()

    userAgent = @model.window.getUserAgent()
    isIos = Environment.isIos {userAgent}
    isAndroid = Environment.isAndroid {userAgent}
    isNative = Environment.isNativeApp 'freeroam', {userAgent}
    isStatusBarVisible = Boolean statusBarData

    if @router.preservedRequest
      $page = @router.preservedRequest?.$page
      $overlayPage = request?.$page
      hasBottomBar = $overlayPage.hasBottomBar
    else
      $page = request?.$page or $backupPage
      hasBottomBar = $page?.$bottomBar

    hasOverlayPage = $overlayPage?

    z 'html', {
      attributes:
        lang: 'en'
    },
      z @$head, {isPlain: $page?.isPlain, meta: $page?.getMeta?()}
      z 'body',
        z '#zorium-root', {
          className: z.classKebab {isIos, isAndroid, hasOverlayPage}
        },
          # used for screenshotting
          if $page?.isPlain
            z '.z-root',
              z '.content', {
                style:
                  height: "#{windowSize.height}px"
              }, $page
          else
            z '.z-root',
              unless hideDrawer
                z @$navDrawer, {currentPath: request?.req.path}

              z '.content', {
                style:
                  height: "#{windowSize.height}px"
              },
                if isStatusBarVisible
                  if statusBarData.type is 'snack'
                    z @$snackBar, {hasBottomBar}
                  else
                    z @$statusBar
                z '.page', {key: 'page'},
                  $page

              if $overlayPage
                z '.overlay-page', {
                  key: 'overlay-page'
                  style:
                    height: "#{windowSize.height}px"
                },
                  z $overlayPage

              _map $overlays, ($overlay) ->
                z $overlay

              z $tooltip

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
