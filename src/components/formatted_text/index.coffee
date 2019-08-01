z = require 'zorium'
supportsWebP = window? and require 'supports-webp'
# remark = require 'remark'
unified = require 'unified'
markdown = require 'remark-parse'
vdom = require 'remark-vdom'
_uniq = require 'lodash/uniq'
_find = require 'lodash/find'
_reduce = require 'lodash/reduce'
RxObservable = require('rxjs/Observable').Observable
require 'rxjs/add/observable/of'

# Sticker = require '../sticker'
FlatButton = require '../flat_button'
ImageViewOverlay = require '../image_view_overlay'
EmbeddedVideo = require '../embedded_video'
ProfileDialog = require '../profile_dialog'
config = require '../../config'

if window?
  require './index.styl'

module.exports = class FormattedText
  constructor: (options) ->
    {text, @imageWidth, @model, @router, @skipImages, @mentionedUsers,
      @isFullWidth, @embedVideos, @truncate
      @useThumbnails} = options

    if text?.map
      $el = text.map((text) => @get$ {text, @model})
    else
      @$el = @get$ {text, @model} # use right away
      $el = null

    if @truncate
      @$readMoreButton = new FlatButton()

    @state = z.state {
      $el: $el
      text: text
      isExpanded: false
    }

  beforeUnmount: =>
    @state.set
      isExpanded: false

  get$: ({text, model, state}) =>
    # isSticker = text?.match /^:[a-z_\^0-9]+:$/
    #
    # stickers = _uniq text?.match /:[a-z_\^0-9]+:/g
    # text = _reduce stickers, (newText, find) ->
    #   stickerText = find.replace /:/g, ''
    #   parts = stickerText.split '^'
    #   sticker = parts[0]
    #   level = parts[1] or 1
    #   findRegex = new RegExp find.replace('^', '\\^'), 'g'
    #   stickerDir = sticker?.split('_')[0]
    #   newText.replace(
    #     findRegex
    #     "![sticker](#{config.CDN_URL}/stickers/#{stickerDir}/" +
    #       "#{sticker}_#{level}_tiny.png)"
    #   )
    # , text

    mentions = text?.match config.MENTION_REGEX
    text = _reduce mentions, (newText, find) ->
      username = find.replace('@', '').toLowerCase()
      newText.replace(
        find
        "[#{find}](/user/#{username} \"user:#{username}\")"
      )
    , text

    unified()
    .use markdown
    .use vdom, {
      # zorium components' states aren't subscribed in here
      components:
        img: (tagName, props, children) =>
          isSticker = props.alt is 'sticker'

          if not props.src or (@skipImages and isSticker)
            return

          imageWidth = if isSticker \
                       then 30
                       else if @imageWidth is 'auto' \
                       then undefined
                       else 200

          imageAspectRatioRegex = /%20=([0-9.]+)/ig
          localImageRegex = ///
            #{config.USER_CDN_URL.replace '/', '\/'}/cm/(.*?)\.
          ///ig
          imageSrc = props.src

          if matches = imageAspectRatioRegex.exec imageSrc
            imageAspectRatio = matches[1]
            imageSrc = imageSrc.replace matches[0], ''
          else
            imageAspectRatio = null

          if matches = localImageRegex.exec imageSrc
            imageSrc = "#{config.USER_CDN_URL}/cm/#{matches[1]}.small.jpg"
            largeImageSrc = "#{config.USER_CDN_URL}/cm/#{matches[1]}.large.jpg"

          if supportsWebP and imageSrc.indexOf('giphy.com') isnt -1
            imageSrc = imageSrc.replace /\.gif$/, '.webp'

          largeImageSrc ?= imageSrc

          if isSticker
            z 'img.is-sticker', {
              src: imageSrc
              width: imageWidth
            }
          else if @useThumbnails
            z '.image-wrapper',
              z 'img', {
                src: imageSrc
                width: imageWidth
                height: if imageAspectRatio and @imageWidth isnt 'auto' \
                        then imageWidth / imageAspectRatio
                        else undefined
                onclick: (e) =>
                  # get rid of keyboard on ios
                  # document.activeElement.blur()
                  e?.stopPropagation()
                  e?.preventDefault()
                  @model.overlay.open new ImageViewOverlay {
                    @model
                    @router
                    imageData:
                      url: largeImageSrc
                      aspectRatio: imageAspectRatio
                  }
              }
          else
            z 'img', {
              src: largeImageSrc
            }

        a: (tagName, props, children) =>
          isMention = props.title and props.title.indexOf('user:') isnt -1
          if isMention
            username = props.title.replace 'user:', ''
            mentionedUser = _find @mentionedUsers, {username}
          youtubeId = props.href?.match(config.YOUTUBE_ID_REGEX)?[1]
          imgurId = props.href?.match(config.IMGUR_ID_REGEX)?[1]

          if youtubeId and @embedVideos
            $embeddedVideo = new EmbeddedVideo {
              model
              video:
                sourceId: youtubeId
            }
            z $embeddedVideo
          else if imgurId and @embedVideos and props.href?.match /\.(gif|mp4|webm)/i
            $embeddedVideo = new EmbeddedVideo {
              model
              video:
                src: "https://i.imgur.com/#{imgurId}.mp4"
                previewSrc: "https://i.imgur.com/#{imgurId}h.jpg"
                mp4Src: "https://i.imgur.com/#{imgurId}.mp4"
                webmSrc: "https://i.imgur.com/#{imgurId}.webm"
            }
            z $embeddedVideo
          # no user found, don't make link
          else if isMention and not mentionedUser
            z 'span', children
          else
            z 'a.link', {
              href: props.href
              className: z.classKebab {isMention}
              onclick: (e) =>
                e?.stopPropagation()
                e?.preventDefault()
                if isMention
                  if mentionedUser
                    @model.overlay.open new ProfileDialog {
                      @model, @router, user: mentionedUser
                    }
                else
                  @router.openLink props.href
            },
              # w/o using raw username for mentions, user_test_
              # will show up in italics
              if isMention then "@#{username}" else children
    }
    .processSync text
    .contents

  render: =>
    {text, isExpanded, $el} = @state.getValue()

    isTruncated = @truncate and text?.length > @truncate.maxLength and
                    not isExpanded

    props =
      className: z.classKebab {@isFullWidth, isTruncated}

    if @minHeight
      props.style = {@minHeight}

    if isTruncated
      props.onclick = => @state.set isExpanded: true

    z '.z-formatted-text', props,
      @$el or $el
      if @truncate
        z '.read-more',
          z @$readMoreButton,
            text: @model.l.get 'general.readMore'
            isFullWidth: true
