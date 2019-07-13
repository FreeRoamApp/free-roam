module.exports = class Region
  namespace: 'regions'

  constructor: ({@auth}) -> null

  getAllByAgencySlug: (agencySlug) =>
    @auth.stream "#{@namespace}.getAllByAgencySlug", {agencySlug}
