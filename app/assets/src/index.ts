import React from 'react';
import { createRoot } from 'react-dom/client';

import App from './components/App'

import './styles/main.scss'


const container = document.getElementById('root') as Element
const root = createRoot(container)
root.render(React.createElement(App));
