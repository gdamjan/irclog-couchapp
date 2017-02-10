import * as React from 'react';
import {render} from 'react-dom';

import router from './app-router';

const root = document.getElementById('app');
render(router, root);
