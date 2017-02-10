function list(head, req) {
  var row;
  start({
    "headers": {
      "Content-Type": "text/html"
    }
  });
  send('<ul class="channels">');
  while(row = getRow()) {
    send('<li><a href="?channel=' +row.key+ '" title="' +row.value+ '">'  +row.key+ '</a></li>');
  }
  send('</ul>');
}; list
