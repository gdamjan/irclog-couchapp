import * as React from 'react';

import {IRCMessage} from './irclog';

function makeRow(msg:IRCMessage) {
    const color = 'rgb(239, 194, 194)';
    const style = {backgroundColor: color};
    const nickname = <span className="nickname" style={style}>{msg.sender}</span>;
/* TODO:
    * https://github.com/banyan/react-emoji
    * https://github.com/banyan/react-autolink
    * message.replace(/^\x01ACTION (.*)\x01/g, $1)
    * choose color
    * do datetime
*/
    const message = <span>{msg.message}</span>;
    const datetime = <span>{msg.timestamp}</span>;
    return (
        <tr key={msg._id}>
            <td className="message">
                {nickname}&nbsp;{message}
            </td>
            <td width="1%" className="timestamp">{datetime}</td>
        </tr>
    )
}

export {makeRow};
