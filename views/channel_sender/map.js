function(doc) {
  if (doc.channel && doc.sender && doc.timestamp)
    emit([doc.channel, doc.sender, doc.timestamp], null);
}
