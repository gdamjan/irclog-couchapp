/*
 *   http://guide.couchdb.org/draft/notifications.html#filters
 *
 */

function tag(doc, req) {
  if (!req.query.tag)
    return false;
  var tag = req.query.tag + '//';
  if(doc.message && doc.message.indexOf(tag) !== -1 ) {
    return true;
  }
  return false;
}; tag
