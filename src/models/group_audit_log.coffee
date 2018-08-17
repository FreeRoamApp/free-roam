module.exports = class GroupAuditLog
  namespace: 'groupAuditLogs'

  constructor: ({@auth}) -> null

  getAllByGroupId: (groupId) =>
    @auth.stream "#{@namespace}.getAllByGroupId", {groupId}
