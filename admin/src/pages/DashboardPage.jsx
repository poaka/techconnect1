import { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import { Users, Wrench, ShieldCheck, Clock, ClipboardList, XCircle, Flag } from 'lucide-react';
import Header from '../components/Header';
import StatCard from '../components/StatCard';
import apiClient from '../api/client';

export default function DashboardPage() {
  const [stats, setStats] = useState(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const navigate = useNavigate();

  const fetchStats = () => {
    setLoading(true);
    setError('');
    apiClient.get('/admin/stats')
      .then(res => setStats(res.data.data))
      .catch(() => setError('Impossible de charger les statistiques.'))
      .finally(() => setLoading(false));
  };

  useEffect(() => { fetchStats(); }, []);

  const statCards = stats ? [
    { label: 'Utilisateurs', value: stats.users_count ?? stats.usersCount, icon: Users, color: '#3B82F6', to: '/users' },
    { label: 'Techniciens', value: stats.technicians_count ?? stats.techniciansCount, icon: Wrench, color: '#F59E0B', to: '/technicians' },
    { label: 'Techniciens Vérifiés', value: stats.verified_technicians_count ?? stats.verifiedTechniciansCount, icon: ShieldCheck, color: '#10B981', to: '/technicians' },
    { label: 'Vérifications en Attente', value: stats.pending_verifications_count ?? stats.pendingVerificationsCount, icon: Clock, color: '#F59E0B', to: '/verifications' },
    { label: 'Demandes de Service', value: stats.service_requests_count ?? stats.serviceRequestsCount, icon: ClipboardList, color: '#8B5CF6', to: '/requests' },
    { label: 'Vérifications Rejetées', value: stats.rejected_verifications_count ?? stats.rejectedVerificationsCount, icon: XCircle, color: '#EF4444', to: '/verifications' },
    { label: 'Signalements', value: stats.reports_count ?? stats.reportsCount, icon: Flag, color: '#EF4444', to: '/reports' },
  ] : [];

  return (
    <>
      <Header title="Tableau de Bord" subtitle="Vue d'ensemble de la plateforme TechConnect" onRefresh={fetchStats} />
      <div className="page-body">
        {loading ? (
          <div className="loading-box"><div className="spinner" /></div>
        ) : error ? (
          <div className="error-alert">
            {error}
            <button className="btn btn-ghost" onClick={fetchStats} style={{ marginLeft: 'auto' }}>Réessayer</button>
          </div>
        ) : (
          <>
            <div className="section-gap">
              <h2 style={{ fontSize: '1rem', fontWeight: 700, marginBottom: 16, color: 'var(--text-secondary)' }}>STATISTIQUES</h2>
              <div className="stats-grid">
                {statCards.map(s => (
                  <StatCard
                    key={s.label}
                    label={s.label}
                    value={s.value}
                    icon={s.icon}
                    color={s.color}
                    onClick={() => navigate(s.to)}
                  />
                ))}
              </div>
            </div>

            <div className="card">
              <div className="card-header">
                <h3 className="card-title">Gestion du Contenu</h3>
              </div>
              <div style={{ padding: '8px 0' }}>
                {[
                  { label: 'Régions & Villes', desc: 'Gérer les régions et les villes disponibles', to: '/regions' },
                  { label: 'Catégories de Services', desc: 'Gérer les catégories de services proposés', to: '/categories' },
                ].map(item => (
                  <div
                    key={item.to}
                    onClick={() => navigate(item.to)}
                    style={{
                      display: 'flex', alignItems: 'center', justifyContent: 'space-between',
                      padding: '16px 24px', cursor: 'pointer', borderBottom: '1px solid var(--border)',
                      transition: 'background 0.15s',
                    }}
                    onMouseEnter={e => e.currentTarget.style.background = 'var(--surface-2)'}
                    onMouseLeave={e => e.currentTarget.style.background = 'transparent'}
                  >
                    <div>
                      <div style={{ fontWeight: 600 }}>{item.label}</div>
                      <div className="text-sm text-secondary">{item.desc}</div>
                    </div>
                    <span style={{ color: 'var(--text-secondary)', fontSize: 20 }}>›</span>
                  </div>
                ))}
              </div>
            </div>
          </>
        )}
      </div>
    </>
  );
}
