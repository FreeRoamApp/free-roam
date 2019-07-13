module.exports = class Mvum
  namespace: 'localMaps'

  constructor: ({@auth}) -> null

  getAllByRegionSlug: (regionSlug, {location} = {}) =>
    @auth.stream "#{@namespace}.getAllByRegionSlug", {
      regionSlug, location
    }

  upsert: ({name, type, url, regionSlug}) =>
    @auth.call "#{@namespace}.upsert", {name, type, url, regionSlug}, {
      invalidateAll: true
    }
