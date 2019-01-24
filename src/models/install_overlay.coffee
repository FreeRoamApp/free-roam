InstallOverlay = require '../components/install_overlay'

module.exports = class InstallOverlayModel
  constructor: ({@l, @overlay}) -> null

  setPrompt: (@prompt) => null

  open: =>
    @overlay.open new InstallOverlay {model: {@l, @overlay}}
    # prevent body scrolling while viewing menu
    document.body.style.overflow = 'hidden'

  close: =>
    @overlay.close()
    document.body.style.overflow = 'auto'
