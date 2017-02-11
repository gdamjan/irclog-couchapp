import * as React from 'react';
import {Link} from 'react-router';

import {fetchChannels} from './irclog';

class HomePage extends React.Component<any, {channels: string[]}> {
    constructor(props: any) {
        super(props);
        this.state = {channels:[]};
    }

    public componentDidMount() {
        fetchChannels()
            .then(channels => this.setState({channels:channels}))
    }

    public componentWillReceiveProps(nextProps: any) {
        this.setState({channels: []});
        fetchChannels()
            .then(channels => this.setState({channels:channels}))
    }

    public render() {
        let channels = this.state.channels.map(c => <li key={c}><Link to={{pathname:c}}>{c}</Link></li>);
        return (
            <header>
                <h1>IRC logs with realtime updates</h1>
                <p>
                    This web page is a viewer of irclogs collected by my
                    <a href="https://github.com/gdamjan/erlang-irc-bot">erlang irc bot</a>.
                    The bot stores the logs in a CouchDB where this web-app (or couchapp)
                    is also stored. You can also <a href="http://wiki.apache.org/couchdb/Replication">replicate</a>
                     the database at https://irc.softver.org.mk/api freely.
                </p>
                <p>
                    The following channels are currently logged:
                </p>
                <ul id="channels">{channels}</ul>
                <p>If you want your irc channel on freenode logged, contact 'damjan' on #lugola.</p>
            </header>
        )
    }
}

export default HomePage;
