import React, { createContext, useContext, useState, useEffect, useCallback } from 'react';
import apiClient from '../api/client';

const AuthContext = createContext(null);

export function AuthProvider({ children }) {
  const [user, setUser] = useState(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);

  // On mount, check if there's an existing token and validate it
  useEffect(() => {
    const token = localStorage.getItem('admin_token');
    if (!token) {
      setLoading(false);
      return;
    }

    apiClient.get('/auth/me')
      .then(res => {
        const userData = res.data.data;
        if (userData.role !== 'admin') {
          // Non-admin user tried to access: boot them out
          localStorage.removeItem('admin_token');
          localStorage.removeItem('admin_user');
          setError('Accès refusé: vous devez être administrateur.');
          setUser(null);
        } else {
          setUser(userData);
        }
      })
      .catch(() => {
        localStorage.removeItem('admin_token');
        localStorage.removeItem('admin_user');
        setUser(null);
      })
      .finally(() => setLoading(false));
  }, []);

  const login = useCallback(async (email, password) => {
    setError(null);
    const res = await apiClient.post('/auth/login', { email, password });
    const { token, user: userData } = res.data.data;

    if (userData.role !== 'admin') {
      throw new Error('Accès refusé. Ce tableau de bord est réservé aux administrateurs.');
    }

    localStorage.setItem('admin_token', token);
    localStorage.setItem('admin_user', JSON.stringify(userData));
    setUser(userData);
    return userData;
  }, []);

  const logout = useCallback(() => {
    localStorage.removeItem('admin_token');
    localStorage.removeItem('admin_user');
    setUser(null);
  }, []);

  return (
    <AuthContext.Provider value={{ user, loading, error, login, logout }}>
      {children}
    </AuthContext.Provider>
  );
}

export function useAuth() {
  const ctx = useContext(AuthContext);
  if (!ctx) throw new Error('useAuth must be used within an AuthProvider');
  return ctx;
}
