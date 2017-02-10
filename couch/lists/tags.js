function list(head, req) {
   var row;
   start({
      "headers": {
         "Content-Type": "text/html"
      }
   });
   send('<ul class="tagcloud">');
   while(row = getRow()) {
      var fontSize = (row.value / 10 < 1) ? row.value / 10 + 1 + "em": (row.value / 10 > 2) ? "2em" : row.value / 10 + "em";
      send('<li><a href="tags/?tag=' +row.key+ '" ' +
           'title="' + row.value + '" ' +
           'style="font-size:' +fontSize+ '">' +
           row.key + '</a></li>');
   }
   send('</ul>');
}; list
