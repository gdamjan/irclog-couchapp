function(doc) {
  if (doc.channel && doc.timestamp)
    emit([doc.channel, doc.timestamp], null);
}
