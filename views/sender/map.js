/*
 * Create an index on the sender and timestamp of the message. That way we can
 * query the index and retreive messages for a single user on all channels, sorted
 * by the timestamp. Usefull for some statistics.
 */

function map(doc) {
  if (doc.sender && doc.timestamp)
    emit([doc.sender.toLowerCase(), doc.timestamp], null);
}; map
