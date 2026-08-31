import axios from 'axios';

// In docker-compose, nginx proxies /api to the backend service.
// In local dev (npm start), set REACT_APP_API_URL=http://localhost:5000
const API_URL = process.env.REACT_APP_API_URL || '/api';

const api = axios.create({
  baseURL: API_URL,
});

api.interceptors.request.use((config) => {
  const token = localStorage.getItem('token');
  if (token) {
    config.headers.Authorization = `Bearer ${token}`;
  }
  return config;
});

export default api;
