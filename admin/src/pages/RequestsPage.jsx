import { useState, useEffect, useCallback } from 'react';
import { ClipboardList } from 'lucide-react';
import Header from '../components/Header';
import apiClient from '../api/client';

const STATUS_OPTIONS = ['all', 'pending', 'accepted', 'in_progress', 'completed', 'cancelled'];
const STATUS_LABELS = { all: 'Tous', pending: 'En attente', accepted: 'Acceptée', in_progress: 'En cours', completed: 'Terminée', cancelled: 'Annulée' };
const STATUS_COLORS = { pending: '#F59E0B', accepted: '#3B82F6', in_progress: '#8B5CF6', completed: '#10B981', cancelled: '#EF4444' };

export default function RequestsPage() {
  const [filter, setFilter] = useState('all');
  const [requests, setRequests] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');

  const fetchRequests = useCallback(() => {
    setLoading(true);
    setError('');
    const params = filter !== 'all' ? `?status=${filter}` : '';
    apiClient.get(`/admin/requests${params}`)
      .then(res => setRequests(res.data.data || []))
      .catch(() => setError('Impossible de charger les demandes.'))
      .finally(() => setLoading(false));
  }, [filter]);

  useEffect(() => { fetchRequests(); }, [fetchRequests]);

  return (
    <>
      <Header title="Demandes de Service" subtitle={`${requests.length} demande(s) trouvée(s)`} onRefresh={fetchRequests} />
      <div className="page-body">
        <div className="page-header">
          <div className="tab-bar" style={{ flexWrap: 'wrap' }}>
            {STATUS_OPTIONS.map(s => (
              <button key={s} className={`tab-btn${filter === s ? ' active' : ''}`} onClick={() => setFilter(s)}>
                {STATUS_LABELS[s]}
              </button>
            ))}
          </div>
        </div>

        <div className="card">
          {loading ? (
            <div className="loading-box"><div className="spinner" /></div>
          ) : error ? (
            <div className="empty-state"><p className="text-error">{error}</p></div>
          ) : requests.length === 0 ? (
            <div className="empty-state">
              <div className="empty-icon"><ClipboardList size={28} style={{ color: 'var(--text-secondary)' }} /></div>
              <p className="font-semibold">Aucune demande trouvée</p>
            </div>
          ) : (
            <div className="table-wrapper">
              <table>
                <thead>
                  <tr>
                    <th>Client</th>
                    <th>Technicien</th>
                    <th>Catégorie</th>
                    <th>Description</th>
                    <th>Statut</th>
                    <th>Date</th>
                  </tr>
                </thead>
                <tbody>
                  {requests.map(req => {
                    const status = req.status || 'pending';
                    const color = STATUS_COLORS[status] || '#64748B';
                    return (
                      <tr key={req.id}>
                        <td>
                          <div className="font-semibold">{req.client?.full_name || '—'}</div>
                          <div className="text-xs text-secondary">{req.client?.email}</div>
                        </td>
                        <td>
                          <div className="font-semibold">{req.technician?.user?.full_name || '—'}</div>
                        </td>
                        <td className="text-secondary">{req.category?.name || '—'}</td>
                        <td>
                          <div style={{ maxWidth: 220, overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}>
                            {req.description || '—'}
                          </div>
                        </td>
                        <td>
                          <span className="badge-pill" style={{ background: `${color}1A`, color }}>
                            {STATUS_LABELS[status] || status}
                          </span>
                        </td>
                        <td className="text-secondary text-sm">
                          {req.created_at ? new Date(req.created_at).toLocaleDateString('fr-FR') : '—'}
                        </td>
                      </tr>
                    );
                  })}
                </tbody>
              </table>
            </div>
          )}
        </div>
      </div>
    </>
  );
}
