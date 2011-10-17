/* bunch of useful routines stolen from all over the internet */
var $Utils = function(document, window, undefined) {

  var exports = {

    /*
     * Python(ish) string formatting:
     * >>> format('{0}', ['zzz'])
     * "zzz"
     * >>> format('{x}', {x: 1})
     * "1"
     */

    format: function (s, args) {
       var re = /\{([^}]+)\}/g;
       return s.replace(re, function(_, match){ return args[match];});
    },


    // http://snippets.dzone.com/posts/show/6995
    // alternatively use jquery.linkify?
    autoLink: function (text, options) {
      function autolinkLabel(text, limit) {
          if (!limit){ return text; }
          if (text.length > limit) {
              return text.substr(0, limit - 3) + '...';
          }
          return text;
      }

      if(!options) options = {};
      if(!options.limit) options.limit = 50;
      if(!options.tagFill) options.tagFill = '';

      var regex = /((http\:\/\/|https\:\/\/|ftp\:\/\/)|(www\.))+(\w+:{0,1}\w*@)?(\S+)(:[0-9]+)?(\/|\/([\w#!:.?+=&%@!\-\/]))?/gi;

      return text.replace(regex, function(value) {
         // value = value.toLowerCase(); ?? misa|_
         var m = value.match(/^([a-z]+:\/\/)/);
         var nice;
         var url;

         if (m) {
            nice = value.replace(m[1],'');
            url = value;
         } else {
            nice = value;
            url = 'http://' + nice;
         }

         return '<a href="' + url + '"' + (options.tagFill != '' ? (' ' + options.tagFill) : '') +
                    '>' + autolinkLabel(nice, options.limit) + '</a>';
      });
    },


    // get query value for key or return default
    // recognizes both & and ; as key=value separators
    getQueryVariable: function (key, _default) {
      var query = window.location.search.substring(1);
      var vars = query.split(/[;&]/);
      for (var i=0; i < vars.length; i++) {
        var pair = vars[i].split("=");
        if (pair[0] == key) { return pair[1]; }
      }
      return _default;
    },


    escapeHTML: function (html) {
      // from zed shaw http://mongrel2.org/chatdemo/app.js
      var trans = {
          '&': '&amp;',
          '<': '&lt;',
          '>': '&gt;',
          '"': '&quot;',
          "'": '&#x27;'
      }
      return (html + '').replace(/[&<>\"\']/g, function(c) { return trans[c]; });
    },


    getCookie: function (c_name) {
       var i,x,y,ARRcookies=document.cookie.split(";");
       for (i=0;i<ARRcookies.length;i++) {
          x=ARRcookies[i].substr(0,ARRcookies[i].indexOf("="));
          y=ARRcookies[i].substr(ARRcookies[i].indexOf("=")+1);
          x=x.replace(/^\s+|\s+$/g,"");
          if (x==c_name) {
             return unescape(y);
          }
       }
    },
    setCookie: function (c_name,value,exdays) {
       var exdate=new Date();
       exdate.setDate(exdate.getDate() + exdays);
       var c_value=escape(value) + ((exdays==null) ? "" : "; expires="+exdate.toUTCString());
       document.cookie=c_name + "=" + c_value;
    }
  }
  return exports;

}(document, window);
