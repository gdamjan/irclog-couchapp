function(doc) {
  if (doc.sender && doc.timestamp)
    emit([doc.sender, doc.timestamp], null);
}
