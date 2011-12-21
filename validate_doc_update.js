/* Access control
 *
 * in CouchDB you need to provide your own access control.
 * this function is called for all incoming requests that modify
 * the database and checks if the user is "irclog" or member of the builtin
 * "_admin" role.
 *
 * http://wiki.apache.org/couchdb/Document_Update_Validation
 */

function validate_doc_update(newDoc, oldDoc, userCtx) {
  if (userCtx.name == "irclog" || userCtx.roles.indexOf("_admin") !== -1) {
    return true;
  }
  throw({"forbidden": "You may not update documents"});
}; validate_doc_update
