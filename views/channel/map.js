/*
 * Create an index on the channel and timestamp of the message. That way we can
 * query the index and retreive messages for a single channel, sorted by the
 * timestamp.
 */

function(doc) {
  if (doc.channel && doc.timestamp)
    emit([doc.channel.toLowerCase(), doc.timestamp], null);
}
