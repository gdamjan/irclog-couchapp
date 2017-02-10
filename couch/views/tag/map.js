/*
 * Create an index of tags in the messages.
 * Tags are in the form of tag//.
 */

function map(doc) {
   if (doc.message && doc.timestamp) {
      var re = new RegExp("(?:\\s|^)(\\S+?)\\/\\/(?:\\s|$)", "mg");
      while ((result = re.exec(doc.message)) != null) {
         emit([result[1].toLowerCase(), doc.timestamp], null);
      }
   }
}; map
