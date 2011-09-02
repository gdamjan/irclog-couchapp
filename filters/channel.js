function(doc, req) {
  if(doc.channel == req.query.channel) {
    return true;
  }
  return false;
}
