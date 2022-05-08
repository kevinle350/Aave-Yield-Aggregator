import './App.css';
import { BrowserRouter, Routes, Route, Outlet } from "react-router-dom";
import Home from './components/pages/Home';


function App() {
    return (
        <BrowserRouter>
            <Routes>
                <Route path='/' element={<Home />} />
                <Route path='/home' element={<Home />} />
            </Routes>
        </BrowserRouter>
    )
}

export default App;
