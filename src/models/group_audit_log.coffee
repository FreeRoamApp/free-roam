module.exports = class GroupAuditLog
  namespace: 'groupAuditLogs'

  constructor: ({@auth}) -> null

  getAllByGroupUuid: (groupUuid) =>
    @auth.stream "#{@namespace}.getAllByGroupUuid", {groupUuid}
