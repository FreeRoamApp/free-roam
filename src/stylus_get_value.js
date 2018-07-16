var colors = require('./colors');

module.exports = function() {
  return function(style) {
    var nodes = this.nodes;
    return style.define('getValue', function(color) {
      isString = typeof color.string === 'string';
      var isVariable = isString && color.string.substring(0, 2) === '--';
      if(isVariable) {
        return new nodes.Literal(colors.default[color.string]);
      }
      else
        return color;
    });
  };
};
