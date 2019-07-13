module.exports = class Office
  namespace: 'offices'

  constructor: ({@auth}) -> null

  getAllByAgencySlugAndRegionSlug: (agencySlug, regionSlug) =>
    @auth.stream "#{@namespace}.getAllByAgencySlugAndRegionSlug", {
      agencySlug, regionSlug
    }
