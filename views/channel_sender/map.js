/*
 * Create an index on the channel, sender and timestamp of the message. That way we can
 * query the index and retreive messages for a user on a channel, sorted by the
 * timestamp.
 */

function(doc) {
  if (doc.channel && doc.sender && doc.timestamp)
    emit([doc.channel, doc.sender, doc.timestamp], null);
}
