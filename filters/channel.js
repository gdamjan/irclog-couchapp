/* Filter functions will allow you to select what documents you get
 * notifications about. In this case, we want to receive notifications for a
 * single channel only. The channel is provided in the query args of the
 * request.
 *
 * http://guide.couchdb.org/draft/notifications.html#filters
 *
 * in this case I filter out notifications about deleted documets too. deleted
 * documents shouldn't happen anyway.
 */

function channel(doc, req) {
  if (!req.query.channel)
    return false;
  if(!doc._deleted && doc.channel && doc.channel == req.query.channel) {
    return true;
  }
  return false;
}; channel
