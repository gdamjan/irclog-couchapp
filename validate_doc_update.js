function(newDoc, oldDoc, userCtx) {
  if (userCtx.name == "irclog" || userCtx.roles.indexOf("_admin") !== -1) {
    return true;
  }
  throw({"forbidden": "You may not update documents"});
}
