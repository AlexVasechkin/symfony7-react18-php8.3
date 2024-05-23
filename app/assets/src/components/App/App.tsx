import { BrowserRouter as Router, Route, Routes } from "react-router-dom";
import HomePage from '../pages/HomePage';
import AboutPage from '../pages/AboutPage';


const App = () => {
  return <div>
    <Router>
      <Routes>
        <Route path={'/'} element={<HomePage />} />
        <Route path={'/about'} element={<AboutPage />} />
      </Routes>

    </Router>
  </div>
}

export default App
