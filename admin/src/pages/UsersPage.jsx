import { useState, useEffect, useCallback } from 'react';
import { Trash2, Users } from 'lucide-react';
import Header from '../components/Header';
import apiClient from '../api/client';

const ROLE_COLORS = { client: '#3B82F6', technician: '#F59E0B', admin: '#EF4444' };
const ROLE_LABELS = { client: 'Client', technician: 'Technicien', admin: 'Admin' };

export default function UsersPage() {
  const [filter, setFilter] = useState('all');
  const [users, setUsers] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [deleteTarget, setDeleteTarget] = useState(null);

  const fetchUsers = useCallback(() => {
    setLoading(true);
    setError('');
    const params = filter !== 'all' ? `?role=${filter}` : '';
    apiClient.get(`/admin/users${params}`)
      .then(res => setUsers(res.data.data || []))
      .catch(() => setError('Impossible de charger les utilisateurs.'))
      .finally(() => setLoading(false));
  }, [filter]);

  useEffect(() => { fetchUsers(); }, [fetchUsers]);

  const handleDelete = async () => {
    if (!deleteTarget) return;
    try {
      await apiClient.delete(`/admin/users/${deleteTarget.id}`);
      setDeleteTarget(null);
      fetchUsers();
    } catch {
      alert('Erreur lors de la suppression.');
    }
  };

  return (
    <>
      <Header title="Gestion des Utilisateurs" subtitle={`${users.length} utilisateur(s) trouvé(s)`} onRefresh={fetchUsers} />
      <div className="page-body">
        <div className="page-header">
          <div className="tab-bar">
            {['all', 'client', 'technician'].map(r => (
              <button key={r} className={`tab-btn${filter === r ? ' active' : ''}`} onClick={() => setFilter(r)}>
                {r === 'all' ? 'Tous' : r === 'client' ? 'Clients' : 'Techniciens'}
              </button>
            ))}
          </div>
        </div>

        <div className="card">
          {loading ? (
            <div className="loading-box"><div className="spinner" /></div>
          ) : error ? (
            <div className="empty-state"><p className="text-error">{error}</p></div>
          ) : users.length === 0 ? (
            <div className="empty-state">
              <div className="empty-icon"><Users size={28} style={{ color: 'var(--text-secondary)' }} /></div>
              <p className="font-semibold">Aucun utilisateur trouvé</p>
            </div>
          ) : (
            <div className="table-wrapper">
              <table>
                <thead>
                  <tr>
                    <th>Utilisateur</th>
                    <th>Email</th>
                    <th>Téléphone</th>
                    <th>Rôle</th>
                    <th>Inscrit le</th>
                    <th>Action</th>
                  </tr>
                </thead>
                <tbody>
                  {users.map(user => {
                    const role = user.role || 'client';
                    const color = ROLE_COLORS[role] || '#64748B';
                    return (
                      <tr key={user.id}>
                        <td>
                          <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
                            <div className="avatar">
                              {user.avatar_url
                                ? <img src={user.avatar_url} alt="" />
                                : (user.full_name?.[0]?.toUpperCase() || '?')
                              }
                            </div>
                            <span className="font-semibold">{user.full_name}</span>
                          </div>
                        </td>
                        <td className="text-secondary">{user.email}</td>
                        <td className="text-secondary">{user.phone || '—'}</td>
                        <td>
                          <span className="badge-pill" style={{ background: `${color}1A`, color }}>
                            {ROLE_LABELS[role] || role}
                          </span>
                        </td>
                        <td className="text-secondary text-sm">
                          {user.created_at ? new Date(user.created_at).toLocaleDateString('fr-FR') : 'N/A'}
                        </td>
                        <td>
                          <button className="btn-icon danger" onClick={() => setDeleteTarget(user)} title="Supprimer">
                            <Trash2 size={16} />
                          </button>
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

      {/* Delete Confirm Modal */}
      {deleteTarget && (
        <div className="modal-overlay" onClick={() => setDeleteTarget(null)}>
          <div className="modal-box" onClick={e => e.stopPropagation()} style={{ maxWidth: 420 }}>
            <div className="modal-header">
              <h2 className="modal-title">Supprimer l'utilisateur</h2>
            </div>
            <div className="modal-body">
              <p>Êtes-vous sûr de vouloir supprimer <strong>{deleteTarget.full_name}</strong> ? Cette action est irréversible.</p>
            </div>
            <div className="modal-footer">
              <button className="btn btn-ghost" onClick={() => setDeleteTarget(null)}>Annuler</button>
              <button className="btn btn-danger" onClick={handleDelete}>Supprimer</button>
            </div>
          </div>
        </div>
      )}
    </>
  );
}
