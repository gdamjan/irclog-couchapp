import * as React from 'react';
import { Router, Route, IndexRoute, hashHistory } from 'react-router';

import HomePage from './view-index';
import AboutPage from './view-about';
import NotFound from './view-notfound';


var router = (
<Router history={hashHistory}>
  <Route path="/">
    <IndexRoute component={HomePage} />
    <Route path="about" component={AboutPage} />

    <Route path="*" component={NotFound} />
  </Route>
</Router>
);

export default router;
