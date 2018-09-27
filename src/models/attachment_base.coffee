config = require '../config'

module.exports = class Attachment
  constructor: ({@auth, @proxy, @exoid}) -> null

  getAllByParentId: (parentId, options = {}) =>
    {sort, skip, limit, ignoreCache} = options
    @auth.stream "#{@namespace}.getAllByParentId", {
      parentId, skip, limit, sort
    }, {ignoreCache}

  getById: (id) =>
    @auth.stream "#{@namespace}.getById", {id}
