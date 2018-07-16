colors = require '../colors'

class ThemeService
  getVariableValue: (color) ->
    variable = color?.match?(/\(([^)]+)\)/)?[1]
    if variable
      colors.default[variable]
    else
      color

module.exports = new ThemeService()
