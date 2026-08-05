import { useState, useEffect, useCallback } from 'react';
import { Flag } from 'lucide-react';
import Header from '../components/Header';
import apiClient from '../api/client';

export default function ReportsPage() {
  const [filter, setFilter] = useState('pending');
  const [reports, setReports] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');

  const fetchReports = useCallback(() => {
    setLoading(true);
    setError('');
    apiClient.get(`/admin/reports?status=${filter}`)
      .then(res => setReports(res.data.data || []))
      .catch(() => setError('Impossible de charger les signalements.'))
      .finally(() => setLoading(false));
  }, [filter]);

  useEffect(() => { fetchReports(); }, [fetchReports]);

  return (
    <>
      <Header title="Signalements" subtitle="Examiner les signalements soumis par les utilisateurs" onRefresh={fetchReports} />
      <div className="page-body">
        <div className="page-header">
          <div className="tab-bar">
            <button className={`tab-btn${filter === 'pending' ? ' active' : ''}`} onClick={() => setFilter('pending')}>En Attente</button>
            <button className={`tab-btn${filter === 'resolved' ? ' active' : ''}`} onClick={() => setFilter('resolved')}>Résolus</button>
          </div>
        </div>

        <div className="card">
          {loading ? (
            <div className="loading-box"><div className="spinner" /></div>
          ) : error ? (
            <div className="empty-state"><p className="text-error">{error}</p></div>
          ) : reports.length === 0 ? (
            <div className="empty-state">
              <div className="empty-icon"><Flag size={28} style={{ color: 'var(--text-secondary)' }} /></div>
              <p className="font-semibold">Aucun signalement trouvé</p>
            </div>
          ) : (
            <div className="table-wrapper">
              <table>
                <thead>
                  <tr>
                    <th>Signalé par</th>
                    <th>Technicien signalé</th>
                    <th>Raison</th>
                    <th>Description</th>
                    <th>Statut</th>
                    <th>Date</th>
                  </tr>
                </thead>
                <tbody>
                  {reports.map(rep => (
                    <tr key={rep.id}>
                      <td>
                        <div className="font-semibold">{rep.reporter?.full_name || '—'}</div>
                        <div className="text-xs text-secondary">{rep.reporter?.email}</div>
                      </td>
                      <td className="font-semibold">{rep.reported_technician?.user?.full_name || '—'}</td>
                      <td>
                        <span className="badge-pill" style={{ background: 'var(--error-bg)', color: 'var(--error)' }}>
                          {rep.reason || '—'}
                        </span>
                      </td>
                      <td>
                        <div style={{ maxWidth: 240, overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}>
                          {rep.description || '—'}
                        </div>
                      </td>
                      <td>
                        <span className={`badge-pill ${rep.status === 'pending' ? 'pending' : 'approved'}`}>
                          {rep.status === 'pending' ? 'En attente' : 'Résolu'}
                        </span>
                      </td>
                      <td className="text-secondary text-sm">
                        {rep.created_at ? new Date(rep.created_at).toLocaleDateString('fr-FR') : '—'}
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          )}
        </div>
      </div>
    </>
  );
}
