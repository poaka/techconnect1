import { Routes, Route, Navigate } from 'react-router-dom';
import { AuthProvider } from './context/AuthContext';
import ProtectedRoute from './components/ProtectedRoute';
import Sidebar from './components/Sidebar';
import LoginPage from './pages/LoginPage';
import DashboardPage from './pages/DashboardPage';
import VerificationsPage from './pages/VerificationsPage';
import UsersPage from './pages/UsersPage';
import TechniciansPage from './pages/TechniciansPage';
import RequestsPage from './pages/RequestsPage';
import ReportsPage from './pages/ReportsPage';
import CategoriesPage from './pages/CategoriesPage';
import RegionsPage from './pages/RegionsPage';

function AdminLayout({ children }) {
  return (
    <div className="admin-layout">
      <Sidebar />
      <main className="main-content">
        {children}
      </main>
    </div>
  );
}

export default function App() {
  return (
    <AuthProvider>
      <Routes>
        <Route path="/login" element={<LoginPage />} />

        <Route
          path="/*"
          element={
            <ProtectedRoute>
              <AdminLayout>
                <Routes>
                  <Route path="/" element={<DashboardPage />} />
                  <Route path="/verifications" element={<VerificationsPage />} />
                  <Route path="/users" element={<UsersPage />} />
                  <Route path="/technicians" element={<TechniciansPage />} />
                  <Route path="/requests" element={<RequestsPage />} />
                  <Route path="/reports" element={<ReportsPage />} />
                  <Route path="/categories" element={<CategoriesPage />} />
                  <Route path="/regions" element={<RegionsPage />} />
                  <Route path="*" element={<Navigate to="/" replace />} />
                </Routes>
              </AdminLayout>
            </ProtectedRoute>
          }
        />
      </Routes>
    </AuthProvider>
  );
}
