/*
 * Create an index on the sender and timestamp of the message. That way we can
 * query the index and retreive messages for a single user on all channels, sorted
 * by the timestamp. Usefull for some statistics.
 */

function(doc) {
  if (doc.sender && doc.timestamp)
    emit([doc.sender, doc.timestamp], null);
}
