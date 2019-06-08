module.exports = class LoginLink
  namespace: 'loginLinks'

  constructor: ({@auth}) -> null

  getByUserIdAndToken: (userId, token) =>
    @auth.stream "#{@namespace}.getByUserIdAndToken", {userId, token}
