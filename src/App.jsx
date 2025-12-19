// src/App.jsx
import React from 'react';
import { BrowserRouter as Router, Routes, Route, Link } from 'react-router-dom';
import Dashboard from './Dashboard';

function Layout() {
  return (
    <div className="min-h-screen flex flex-col">
      <nav className="bg-slate-950 border-b border-slate-800 px-8 py-4 flex justify-between items-center">
        <div className="font-bold text-xl text-blue-400 tracking-wider">DEV<span className="text-white">OPS</span></div>
        <div className="space-x-6 text-sm">
          <Link to="/" className="hover:text-blue-400 transition-colors">Dashboard</Link>
          <Link to="/settings" className="hover:text-blue-400 transition-colors">Settings</Link>
        </div>
      </nav>
      <main className="flex-grow container mx-auto">
        <Routes>
          <Route path="/" element={<Dashboard />} />
          <Route path="/settings" element={
            <div className="p-8 text-center text-slate-400">
              <h2 className="text-2xl text-white mb-2">System Settings</h2>
              <p>Configuration options are locked in this environment.</p>
            </div>
          } />
        </Routes>
      </main>
      <footer className="bg-slate-950 py-6 text-center text-slate-600 text-sm">
        GKE CI/CD Pipeline Demo v1.0.0
      </footer>
    </div>
  );
}

export default function App() {
  return (
    <Router>
      <Layout />
    </Router>
  );
}