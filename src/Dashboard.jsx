// src/Dashboard.jsx
import React, { useState } from 'react';

const StatusCard = ({ title, status, ping }) => (
  <div className="bg-slate-800 p-6 rounded-lg shadow-lg border border-slate-700">
    <div className="flex justify-between items-center mb-4">
      <h3 className="text-lg font-semibold text-slate-300">{title}</h3>
      <span className={`px-3 py-1 rounded-full text-xs font-bold ${
        status === 'Healthy' ? 'bg-green-900 text-green-300' : 'bg-red-900 text-red-300'
      }`}>
        {status}
      </span>
    </div>
    <div className="text-slate-400 text-sm">Latency: <span className="text-white">{ping}ms</span></div>
  </div>
);

export default function Dashboard() {
  const [lastUpdated, setLastUpdated] = useState(new Date().toLocaleTimeString());

  return (
    <div className="p-8">
      <div className="flex justify-between items-end mb-8">
        <div>
          <h1 className="text-3xl font-bold text-white">GKE Production Monitor</h1>
          <p className="text-slate-400 mt-2">Real-time infrastructure telemetry</p>
        </div>
        <button 
          onClick={() => setLastUpdated(new Date().toLocaleTimeString())}
          className="bg-blue-600 hover:bg-blue-500 text-white px-4 py-2 rounded transition-colors"
        >
          Refresh Data
        </button>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
        <StatusCard title="User Service" status="Healthy" ping="24" />
        <StatusCard title="Payment Gateway" status="Healthy" ping="115" />
        <StatusCard title="Notification Hub" status="Healthy" ping="45" />
      </div>

      <div className="mt-8 text-xs text-slate-500 text-right">
        Last sync: {lastUpdated}
      </div>
    </div>
  );
}