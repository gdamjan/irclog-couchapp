/*
 * Create an index of tags in the messages.
 * Tags are in the form of tag//.
 */

function(doc) {
   if (doc.message && doc.timestamp) {
      var re = /(?:\s|^)(\S+?)\/\/(?:\s|$)/mg;
      while ((result = re.exec(doc.message)) != null) {
         emit([result[1].toLowerCase(), doc.timestamp], null);
      }
   }
}
