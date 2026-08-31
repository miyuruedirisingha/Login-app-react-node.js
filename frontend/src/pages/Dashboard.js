import React, { useEffect, useState } from 'react';
import { useNavigate } from 'react-router-dom';
import api from '../api';

export default function Dashboard() {
  const [profile, setProfile] = useState(null);
  const [error, setError] = useState('');
  const navigate = useNavigate();

  useEffect(() => {
    const fetchProfile = async () => {
      try {
        const res = await api.get('/auth/profile');
        setProfile(res.data.user);
      } catch (err) {
        setError('Session expired, please login again');
        localStorage.removeItem('token');
        setTimeout(() => navigate('/login'), 1500);
      }
    };
    fetchProfile();
  }, [navigate]);

  const handleLogout = () => {
    localStorage.removeItem('token');
    localStorage.removeItem('user');
    navigate('/login');
  };

  return (
    <div className="auth-container">
      <div className="auth-form">
        <h2>Dashboard</h2>
        {error && <p className="error">{error}</p>}
        {profile && (
          <div>
            <p>Welcome, {profile.name}!</p>
            <p>Email: {profile.email}</p>
          </div>
        )}
        <button onClick={handleLogout}>Logout</button>
      </div>
    </div>
  );
}
