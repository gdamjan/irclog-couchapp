import * as React from 'react';
import {Link} from 'react-router';

class HomePage extends React.Component<any, any> {
    constructor(props: any) {
        super(props);
    }

    public render() {
        return (
        <div>
            <h1>Hello World!</h1>
            check the <Link to='/about'>about</Link><br/>
            or perhaps the <Link to='/xyz/abc/mgh'>not existing page</Link><br/>
        </div>);
    }
}

export default HomePage;
