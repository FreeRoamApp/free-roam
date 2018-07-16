module.exports = class Nps
  namespace: 'nps'

  constructor: ({@auth}) -> null

  create: ({score, comment}) =>
    @auth.call "#{@namespace}.create", {score, comment}
