
interface IRCMessage {_id:string, _rev:string, sender:string, channel:string, message:string, timestamp:number};
type IRCRows = IRCMessage[];

interface Params {
    [key: string]: string|number|boolean;
}

function URL(url:string, params?:Params) {
    if (params === undefined) {
        return url;
    }
    let esc = encodeURIComponent;
    return url + '?' + Object.keys(params)
             .map(k => esc(k) + '=' + esc(params[k].toString()))
             .join('&')
}

const headers = {'Accept': 'application/json'};
const init:RequestInit = {mode:'cors', method:'GET', headers: headers};

function fetchChannels(): Promise<string[]> {
    let url = 'https://irc.softver.org.mk/ddoc/_view/channel';
    let q = {update_seq:true, reduce: true, group_level: 1};

    return fetch(URL(url, q), init)
        .then(response => response.json())
        .then((json:any) => json.rows.map((x:any)=>x.key[0]));
}


function fetchRows(channel: string): Promise<IRCRows> {
    let url = 'https://irc.softver.org.mk/ddoc/_view/channel';
    let q = { update_seq: true, reduce:false,
        startkey: JSON.stringify([channel, {}]),
        endkey: JSON.stringify([channel, 0]),
        include_docs: true,
        limit:100,
        descending:true
    };

    return fetch(URL(url, q), init)
        .then(response => response.json())
        .then((json:any) => json.rows.map((x:any)=>x.doc));
}

export {IRCMessage, IRCRows, fetchRows, fetchChannels}
