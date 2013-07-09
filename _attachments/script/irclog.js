jQuery(function ($) {

   // GLOBALS
   var focused = false;
   $(window).focus(function () { focused = true; });
   $(window).blur(function () { focused = false; });

   var irclog = $("#irclog");
   var cachedTBodySegments, changes_feed;
   var secret_always_scroll_to_bottom = $Utils.getQueryVariable("auto-scroll", false);
   var pagination = {};
   // GLOBALS

   Path.root("#start");
   Path.map("#start").to(function() {
      $('#infobox').show();
      $('#container').hide();
      var channels = $('#channels');
      channels.html('');

      var v = $Couch.view("channel", {group_level:1, reduce:true});
      v.done(function(data) {
         var i, len = data.rows.length;
         for (i=0; i<len; i++) {
            var title = data.rows[i].key[0];
            var weight = data.rows[i].value;
            var href = '#/' + title;
            var link = $('<a>').attr('href', href).text(title);
            channels.append($('<li>').append(link));
         }
      });
   });

   function init_viewer(channel) {
      $('#infobox').hide();
      $('#container').show();
      $('title').text('logs for #' + channel);
      $('header h1').text('logs for #' + channel);
      irclog.html('');
      cachedTBodySegments = {};
   }

   Path.map("#/:channel").to(function() {
      var channel = this.params['channel'];
      init_viewer(channel);

      if (changes_feed) { changes_feed.stop() };
      pagination.begin = [channel, {}];
      pagination.end = [channel, 0];
      $('#next_page').hide();
      loadPrevPage(channel, true).done(function (data) {
         setTimeout(function () {
            changes_feed = startUpdates(channel, data.update_seq)
         }, 1000);
      });
   });

   Path.map("#/:channel/:date").to(function() {
      var channel = this.params['channel'];
      init_viewer(channel);

      var date = this.params['date'];
      var tzStr = $Utils.getLocalTimezone(date);
      if ($Utils.isNumber(date)) {
         var timestamp = parseInt(date);
      } else if (date.length <= 10) {
         // it's only a date, append a null time
         var timestamp = new Date(date + 'T00:00:00' + tzStr).getTime() / 1000;
      } else if (/[zZ+]/.test(date)) {
         // has timezone
         var timestamp = new Date(date).getTime() / 1000;
      } else {
         // didn't have a timezone yet, append the local
         var timestamp = new Date(date+tzStr).getTime() / 1000;
      }
      loadFullDay(channel, timestamp);
   });


   var paginationClick = function(ev) {
      var self = $(this);
      self.unbind('click');
      var loadPageFun = ev.data;
      loadPageFun().always(function() {
         self.click(loadPageFun, paginationClick);
      });
   }
   $('#prev_page').click(loadPrevPage, paginationClick);
   $('#next_page').click(loadNextPage, paginationClick);

   $('#settings a').click(function() {
      TINY.box.show({url:this.href});
      return false;
   });

   function timestampToDatetime(timestamp) {
      var dt = new Date(timestamp * 1000);
      return {
         date: dt.getFullYear() + '-' + $Utils.pad(dt.getMonth() + 1) + '-' + $Utils.pad(dt.getDate()),
         time: $Utils.pad(dt.getHours()) + ':' + $Utils.pad(dt.getMinutes()) + ':' + $Utils.pad(dt.getSeconds())
      }
   }

   function fmtMessage(doc, color) {
      var out, msg;
      out = '<span class="nickname" style="background-color:' + color + '">' + doc.sender + '</span>';
      msg = $Utils.escapeHTML(doc.message);
      msg = $Utils.autoLink(msg);
      msg = msg.replace(/^\x01ACTION (.*)\x01/g, '<span class="nickname" style="background-color:' + color + '">$1</span>');
      out += ' <span>' + msg + '</span>';
      return out;
   }

   function makeTableRow(message, permalink, anchor, datetime) {
      var out = '';
      out += '<tr>';
      out += '<td class="message">' + message + '</td>';
      out += '<td valign="top" class="timestamp" width="1%">';
      out += '<a id="' + anchor + '" href="' + permalink + '">' + datetime.time + '</a>';
      out += '</td>';
      out += '</tr>\n';
      return out;
   }

   function displayRows(rows, descending) {
      var i, len = rows.length;
      for (i=0; i<len; i++) {
         var doc = rows[i].doc;
         var color = $Colorizer(doc.sender.toLowerCase());
         var datetime = timestampToDatetime(doc.timestamp);
         var permalink = '#/' + doc.channel +
                   '/' + datetime.date + 'T' + datetime.time;
         var anchor = datetime.date + 'T' + datetime.time;
         var msg = fmtMessage(doc, color);
         var row = makeTableRow(msg, permalink, anchor, datetime);
         var tbody = getTableSegment(doc.channel, datetime.date);
         if (descending) {
            $(tbody.children()[0]).after(row);
         } else {
            tbody.append(row);
         }
      }
   }

   function getTableSegment(channel, date) {
      var tbody = cachedTBodySegments[date];
      if (tbody !== undefined)
         return tbody;
      tbody = $('<tbody>');
      tbody.attr('id', date);
      cachedTBodySegments[date] = tbody;
      var link = '<a href="#/' + channel + '/' + date + '">' + date + '</a>';
      tbody.append('<tr class="date"><th colspan="2"><span>' + link + '</span></th></tr>');

      var bodies = irclog.children('tbody');
      var i, done = false;
      for (i=0; i<bodies.length; i++) {
         if (date < bodies[i].id) {
            $(bodies[i]).before(tbody);
            done = true;
            break;
         }
      }
      if (!done) irclog.append(tbody);

      return tbody;
   }


   function loadPrevPage(channel, initial) {
      var v = $Couch.view("channel", {
         startkey: pagination.begin,
         endkey: [channel, 0],
         include_docs: true,
         limit: 100,
         descending: true
      }).done(function (data) {
         if (data.rows.length < 100) {
            // it's the begining of history
            $('#prev_page').hide();
            pagination.begin = [channel, {}];
         } else {
            var last = data.rows.slice(-1)[0];
            pagination.begin = last.key;
            if(initial!==true) {
               data.rows.shift();
            }
         }
         displayRows(data.rows, true);
      });
      return v;
   }

   /**
    * Given a timestamp will load 24h after it
    * @param timestamp in seconds
    * @return a jQuery Deferred object from the query request
    */
   function loadFullDay(channel, timestamp) {
      var until = timestamp + 24 * 60 * 60;
      var v = $Couch.view("channel", {
         startkey: [channel, timestamp],
         endkey: [channel, until],
         include_docs: true,
         descending: false
      }).done(function (data) {
         var last = data.rows.slice(-1)[0];
         var first = data.rows[0];
         if (first) {
            pagination.begin = first.key;
         } else {
            pagination.begin = [channel, {}];
         }
         if (last) {
            pagination.end = last.key;
         } else {
            pagination.end = [channel, 0];
         }
         displayRows(data.rows);
      });
      return v;
   }


   function loadNextPage(channel) {
      var v = $Couch.view("channel", {
         startkey: pagination.end,
         endkey: [channel, {}],
         include_docs: true,
         limit: 100,
         descending: false
      }).done(function (data) {
         if (data.rows.length < 100) {
            // it's the end of history, i.e. the present
            // so start the realtime updates
            $('#next_page').hide();
            pagination.end = [channel, 0];
            changes_feed = startUpdates(channel, data.update_seq);
         } else {
            var last = data.rows.slice(-1)[0];
            pagination.end = last.key;
            data.rows.shift();
         }
         displayRows(data.rows);
      });
      return v;
   }


   // callback, called when new data arrives from the _changes notification feed
   function do_changes(data) {
      displayRows(data.results);
      if (secret_always_scroll_to_bottom) {
         window.scroll(window.scrollX, document.body.clientHeight);
      } else if (!focused) {
         $TitleAlert.start();
      } else if (document.documentElement.scrollHeight - 100 <
            document.documentElement.clientHeight + window.pageYOffset) {
         // view is at the bottom of the document, scroll down to the end
         window.scroll(window.scrollX, document.body.clientHeight);
      } else {
         // notify just the last 5 (only happens on huge changes)
         var noticies = data.results.slice(-5);
         for (var i=0; i<noticies.length; i++) {
            var doc = noticies[i].doc;
            $.noticeAdd({text: "<b>" + doc.sender + ": </b>" + doc.message});
         }
      }
   }

   function startUpdates(channel, last_update_seq) {
      var query = {
         include_docs: true,
         filter: "log/channel",
         channel: channel
      }
      var ch = $Couch.changes(last_update_seq, query);
      ch.on_changes(do_changes);
      ch.on_error(function (err, exc) {
         if (console && console.log)
            console.log(err, exc);
      });
      ch.start();
      return ch;
   }

   Path.listen();
});
