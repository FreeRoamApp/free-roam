z = require 'zorium'
Environment = require '../../services/environment'
RxObservable = require('rxjs/Observable').Observable
require 'rxjs/add/observable/combineLatest'
require 'rxjs/add/operator/do'
_merge = require 'lodash/merge'
_map = require 'lodash/map'
_mapValues = require 'lodash/mapValues'
_defaults = require 'lodash/defaults'
_kebabCase = require 'lodash/kebabCase'

config = require '../../config'
colors = require '../../colors'
fontsCss = require './fonts'

DEFAULT_IMAGE = 'https://fdn.uno/d/images/web_icon_256.png'

module.exports = class Head
  constructor: ({@model, meta, requests, serverData, group}) ->
    route = requests.map ({route}) ->
      route
    path = requests.map ({req}) ->
      req.path
    requestsAndLanguage = RxObservable.combineLatest(
      requests, @model.l.getLanguage(), (vals...) -> vals
    )
    meta = requestsAndLanguage.switchMap ([{$page}, language]) ->
      meta = $page?.getMeta?()
      if meta?.map
        meta
      else
        RxObservable.of meta

    @lastGroupId = null
    @bundlePath = serverData?.bundlePath or
      document?.getElementById('bundle')?.src
    @bundleCssPath = serverData?.bundleCssPath or
      document?.getElementById('bundle-css')?.href

    @state = z.state
      meta: meta
      serverData: serverData
      route: route
      path: path
      # group: group
      routeKey: route.map (route) =>
        if route?.src
          routeKey = @model.l.getRouteKeyByValue route.src
      modelSerialization: unless window?
        @model.getSerializationStream()
      additionalCss: @model.additionalScript.getCss()
      cssVariables: @_getCssVariables()

  _getCssVariables: ->
    cssColors = colors.default
    cssColors['--drawer-header-500'] ?= cssColors['--primary-500']
    cssColors['--drawer-header-500-text'] ?= cssColors['--primary-500-text']
    cssVariables = _map(cssColors, (value, key) ->
      "#{key}:#{value}"
    ).join ';'
    cssVariables

    # group?.map (group) =>
    #   groupSlug = group?.slug
    #
    #   cssColors = _defaults colors[groupSlug], colors.default
    #   cssColors['--drawer-header-500'] ?= cssColors['--primary-500']
    #   cssColors['--drawer-header-500-text'] ?= cssColors['--primary-500-text']
    #   cssVariables = _map(cssColors, (value, key) ->
    #     "#{key}:#{value}"
    #   ).join ';'
    #
    #   if @lastGroupId isnt group?.id
    #     newStatusBarColor = cssColors['--status-bar-500'] or
    #                         cssColors['--primary-900']
    #     @model.portal?.call 'statusBar.setBackgroundColor', {
    #       color: newStatusBarColor
    #     }
    #     @lastGroupId = group?.id
    #     @model.cookie.set 'lastGroupId', group?.id
    #     @model.cookie.set "group_#{group?.id}_lastVisit", Date.now()
    #     if cssVariables
    #       @model.cookie.set 'cachedCssVariables', cssVariables
    #
    #   cssVariables

  render: ({isPlain} = {}) =>
    {meta, serverData, path, route, routeKey, group, additionalCss,
      modelSerialization, cssVariables} = @state.getValue()

    gaId = 'UA-123979730-1'
    gaSampleRate = 100

    paths = _mapValues @model.l.getAllPathsByRouteKey(routeKey), (path) ->
      pathVars = path.match /:([a-zA-Z0-9-]+)/g
      _map pathVars, (pathVar) ->
        path = path.replace pathVar, route.params[pathVar.substring(1)]
      path

    userAgent = @model.window.getUserAgent()

    meta = _merge {
      title: @model.l.get 'meta.defaultTitle'
      icon256: "#{config.CDN_URL}/web_icon_256.png"
      twitter:
        siteHandle: '@freeroamapp'
        creatorHandle: '@freeroamapp'
        # title: undefined
        # description: undefined
        # # min 280 x 150 < 1MB
        # image: 'https://fdn.uno/d/images/web_icon_1024.png'

      openGraph:
        title: undefined
        url: undefined
        description: undefined
        siteName: 'FreeRoam'
        image: DEFAULT_IMAGE

      ios:
        # min 152 x 152
        icon: undefined

      canonical: "https://#{config.HOST}#{path or ''}"
      themeColor: colors.getRawColor colors.$primaryMain
      # reccomended 32 x 32 png
      favicon: config.CDN_URL + '/favicon.png'
      manifestUrl: '/manifest.json'
    }, meta

    meta.title = "#{group?.name or ''} #{meta.title} | FreeRoam"

    meta = _merge {
      # twitter:
      #   title: meta.title
      #   description: meta.description
      openGraph:
        title: meta.title
        url: meta.canonical
        description: meta.description
      ios:
        icon: meta.icon256
    }, meta

    {twitter, openGraph, ios} = meta

    isInliningSource = config.ENV is config.ENVS.PROD
    webpackDevUrl = config.WEBPACK_DEV_URL
    isNative = Environment.isNativeApp('freeroam', {userAgent})
    host = serverData?.req?.headers.host or window?.location?.host

    z 'head',
      z 'title', "#{meta.title}"
      unless isPlain # for screenshotter rendering
        [
          if meta.description
            z 'meta', {name: 'description', content: "#{meta.description}"}

          # mobile
          z 'meta',
            name: 'viewport'
            content: 'initial-scale=1.0, width=device-width, minimum-scale=1.0,
                      maximum-scale=1.0, user-scalable=0, minimal-ui,
                      viewport-fit=cover'

          z 'meta',
            'http-equiv': 'Content-Security-Policy'
            content: "default-src 'self' file://* *; style-src 'self'" +
              " 'unsafe-inline'; script-src 'self' 'unsafe-inline' 'unsafe-eval'"


          # Twitter card
          z 'meta', {
            name: 'twitter:card'
            content: if openGraph.image and openGraph.image isnt DEFAULT_IMAGE \
                     then 'summary_large_image'
                     else 'summary'
          }
          z 'meta', {name: 'twitter:site', content: "#{twitter.siteHandle}"}
          z 'meta', {name: 'twitter:creator', content: "#{twitter.creatorHandle}"}
          # z 'meta', {
          #   name: 'twitter:title'
          #   content: "#{twitter.title or meta.title}"
          # }
          # z 'meta', {
          #   name: 'twitter:description'
          #   content: "#{twitter.description or meta.description}"
          # }
          # z 'meta', {name: 'twitter:image', content: "#{twitter.image}"}

          # Open Graph
          z 'meta', {property: 'og:title', content: "#{openGraph.title}"}
          z 'meta', {property: 'og:type', content: 'website'}
          if openGraph.url
            z 'meta', {property: 'og:url', content: "#{openGraph.url}"}
          z 'meta', {property: 'og:image', content: "#{openGraph.image}"}
          if openGraph.description
            z 'meta', {
              property: 'og:description', content: "#{openGraph.description}"
            }
          z 'meta', {property: 'og:site_name', content: "#{openGraph.siteName}"}

          # iOS
          z 'meta', {name: 'apple-mobile-web-app-capable', content: 'yes'}
          z 'link#apple-touch-icon', {rel: 'apple-touch-icon', href: "#{ios.icon}"}

          # misc
          if meta.canonical
            z 'link#canonical', {rel: 'canonical', href: "#{meta.canonical}"}
          z 'meta', {name: 'theme-color', content: "#{meta.themeColor}"}
          z 'link#favicon', {rel: 'icon', href: "#{meta.favicon}"}
          z 'meta', {name: 'msapplication-tap-highlight', content: 'no'}
          z 'link#gfonts-preconnect', { # faster dns for fonts
            rel: 'preconnect'
            href: 'https://fonts.gstatic.com/'
          }


          # Android
          z 'link#manifest', {rel: 'manifest', href: "#{meta.manifestUrl}"}

          # serialization
          z 'script#model.model',
            key: 'model'
            innerHTML: modelSerialization or ''


          z 'script#ga1',
            key: 'ga1'
            innerHTML: "
              window.ga=window.ga||function(){(ga.q=ga.q||[]).push(arguments)};
              ga.l=+new Date;
              ga('create', '#{gaId}', 'auto', {
                sampleRate: #{gaSampleRate}
              });
              window.addEventListener('error', function(e) {
                ga(
                  'send', 'event', 'error', e.message, e.filename + ':  ' + e.lineno
                );
              });
            "
          z 'script#ga2',
            key: 'ga2'
            async: true
            src: 'https://www.google-analytics.com/analytics.js'
      ]
      z 'style#fonts', {key: 'fonts'}, fontsCss

      # styles
      z 'style#css-variables',
        key: 'css-variables'
        innerHTML:
          ":root {#{cssVariables or @model.cookie.get 'cachedCssVariables'}}"
      if isInliningSource
        z 'link#bundle-css',
          rel: 'stylesheet'
          type: 'text/css'
          href: @bundleCssPath
      else
        null

      # z 'link'
      _map additionalCss, (href) ->
        z "link##{_kebabCase(href)}",
          key: href
          rel: 'stylesheet'
          href: href

      # scripts
      z 'script#bundle',
        key: 'bundle'
        async: true
        src: @bundlePath or "#{config.WEBPACK_DEV_URL}/bundle.js"

      # any conditional scripts need to be at end or else they interfere with others
      if meta.structuredData
        z 'script#structured-data', {
          key: 'structured-data'
          type: 'application/ld+json'
          innerHTML: JSON.stringify {
            '@context': 'http://schema.org'
            '@type': meta.structuredData.type or 'LocalBusiness'
            'name': meta.structuredData.name
            'aggregateRating': {
              '@type': 'AggregateRating'
              'ratingValue': meta.structuredData.ratingValue
              'ratingCount': meta.structuredData.ratingCount
            }
          }
        }


       # TODO: have these update with the router, not just on pageload
       # maybe route should do a head re-render, so it doesn't ave to do it for
       # every render
      #  _map paths, (path, lang) ->
      #    z "link#alternate-#{path}-#{lang}", {
      #      key: "alternate-#{path}-#{lang}"
      #      rel: 'alternate'
      #      href: "https://#{config.HOST}#{path}"
      #      hreflang: lang
      #    }

      # unless isNative
      #   [
      #     z 'script#adsense',
      #       key: 'adsense'
      #       async: true
      #       src: '//pagead2.googlesyndication.com/pagead/js/adsbygoogle.js'
      #     z 'script#stripe1',
      #       key: 'stripe1'
      #       # async: true
      #       src: 'https://js.stripe.com/v2/'
      #     z 'script#stripe2',
      #       key: 'stripe2'
      #       # async: true
      #       innerHTML: "
      #         Stripe.setPublishableKey('#{config.STRIPE_PUBLISHABLE_KEY}');
      #       "
      #   ]
