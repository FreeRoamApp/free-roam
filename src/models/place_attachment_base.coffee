AttachmentBase = require './attachment_base'

module.exports = class PlaceAttachmentBase extends AttachmentBase
  namespace: 'placeAttachments'

  getAllByUserId: (userId) =>
    @auth.stream "#{@namespace}.getAllByUserId", {userId}
