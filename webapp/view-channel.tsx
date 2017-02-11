import * as React from 'react';

import {fetchRows, IRCRows} from './irclog';
import {makeRow} from './view-message';


class MessageList extends React.Component<{rows:IRCRows}, any> {
    public render() {
        let rows = this.props.rows
                .sort((a,b) => a.timestamp-b.timestamp)
                .map(msg => makeRow(msg))
        return <table id="irclog"><tbody>{rows}</tbody></table>;
    }
}

class Channel extends React.Component<any, any> {
    constructor(props: any) {
        super(props);
        this.state = {rows: []};
    }
    fetchRows(channel:string) {
        fetchRows(channel)
            .then(rows => this.setState({rows:rows}))
    }
    public componentDidMount() {
        this.fetchRows(this.props.params.channel);
    }

    public componentWillReceiveProps(nextProps: any) {
        if (this.props.params.channel !== nextProps.params.channel) {
            this.setState({rows: []})
            this.fetchRows(nextProps.params.channel);
        }
    }

    public render() {return (
      <div>
        <header><h1>logs for #{this.props.params.channel}</h1></header>
        <MessageList rows={this.state.rows} />
      </div>
    )}
}

const ChannelDatetime = Channel;
export {Channel, ChannelDatetime };
