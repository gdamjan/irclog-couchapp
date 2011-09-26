"use strict";

var $Colorizer = (function (GLOBAL, undefined) {
  var colors = {};

  var used = 0;
  var max = 100;
  function getColor(key) {
    if (used == max) {
      return "#fff";
    }
    if (colors[key] === undefined) {
      var r = Math.floor(128 + Math.random()*128)<<16;
      var g = Math.floor(128 + Math.random()*128)<<8;
      var b = Math.floor(128 + Math.random()*128);
      colors[key] = '#' + (r+g+b).toString(16);
      used++;
    }
    return colors[key];
  }
  return getColor;
})(window);
