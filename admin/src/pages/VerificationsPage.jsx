import { useState, useEffect, useCallback } from 'react';
import { FileSearch } from 'lucide-react';
import Header from '../components/Header';
import DocumentViewer from '../components/DocumentViewer';
import apiClient from '../api/client';

export default function VerificationsPage() {
  const [tab, setTab] = useState('pending');
  const [docs, setDocs] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [selected, setSelected] = useState(null);

  const fetchDocs = useCallback(() => {
    setLoading(true);
    setError('');
    const url = tab === 'pending' ? '/admin/verifications' : '/admin/verifications/rejected';
    apiClient.get(url)
      .then(res => setDocs(res.data.data || []))
      .catch(() => setError('Impossible de charger les vérifications.'))
      .finally(() => setLoading(false));
  }, [tab]);

  useEffect(() => { fetchDocs(); }, [fetchDocs]);

  const handleApprove = async (docId) => {
    try {
      await apiClient.patch(`/admin/verifications/${docId}`, { status: 'approved' });
      setSelected(null);
      fetchDocs();
    } catch {
      alert('Erreur lors de l\'approbation.');
    }
  };

  const handleReject = async (docId, reason) => {
    try {
      await apiClient.patch(`/admin/verifications/${docId}`, { status: 'rejected', rejectionReason: reason });
      setSelected(null);
      fetchDocs();
    } catch {
      alert('Erreur lors du rejet.');
    }
  };

  const statusColor = { pending: '#F59E0B', approved: '#10B981', rejected: '#EF4444' };

  return (
    <>
      <Header
        title="Vérifications de Documents"
        subtitle="Approuver ou rejeter les documents soumis par les techniciens"
        onRefresh={fetchDocs}
      />
      <div className="page-body">
        <div className="page-header">
          <div className="tab-bar">
            <button className={`tab-btn${tab === 'pending' ? ' active' : ''}`} onClick={() => setTab('pending')}>
              En Attente
            </button>
            <button className={`tab-btn${tab === 'rejected' ? ' active' : ''}`} onClick={() => setTab('rejected')}>
              Rejetées
            </button>
          </div>
        </div>

        <div className="card">
          {loading ? (
            <div className="loading-box"><div className="spinner" /></div>
          ) : error ? (
            <div className="empty-state"><p className="text-error">{error}</p></div>
          ) : docs.length === 0 ? (
            <div className="empty-state">
              <div className="empty-icon"><FileSearch size={28} style={{ color: 'var(--text-secondary)' }} /></div>
              <p className="font-semibold">Aucun document trouvé</p>
              <p className="text-sm text-secondary">
                {tab === 'pending' ? 'Aucune vérification en attente — tout est à jour !' : 'Aucun document rejeté.'}
              </p>
            </div>
          ) : (
            <div className="table-wrapper">
              <table>
                <thead>
                  <tr>
                    <th>Technicien</th>
                    <th>Email</th>
                    <th>Type de document</th>
                    <th>Ville</th>
                    <th>Date de soumission</th>
                    <th>Statut</th>
                    <th>Action</th>
                  </tr>
                </thead>
                <tbody>
                  {docs.map(doc => {
                    const tech = doc.technician || {};
                    const user = tech.user || {};
                    const city = tech.city || {};
                    const status = doc.status || 'pending';
                    return (
                      <tr key={doc.id}>
                        <td>
                          <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
                            <div className="avatar">
                              {user.avatar_url
                                ? <img src={user.avatar_url} alt="" />
                                : (user.full_name?.[0]?.toUpperCase() || '?')
                              }
                            </div>
                            <span className="font-semibold">{user.full_name || 'Inconnu'}</span>
                          </div>
                        </td>
                        <td className="text-secondary">{user.email || 'N/A'}</td>
                        <td>
                          <span className="badge-pill" style={{ background: 'var(--primary-subtle)', color: 'var(--primary)' }}>
                            {doc.document_type?.toUpperCase() || 'N/A'}
                          </span>
                        </td>
                        <td className="text-secondary">{city.name || 'N/A'}</td>
                        <td className="text-secondary text-sm">
                          {doc.uploaded_at ? new Date(doc.uploaded_at).toLocaleDateString('fr-FR') : 'N/A'}
                        </td>
                        <td>
                          <span className="badge-pill" style={{ background: `${statusColor[status]}1A`, color: statusColor[status] }}>
                            {status === 'pending' ? 'En attente' : status === 'approved' ? 'Approuvé' : 'Rejeté'}
                          </span>
                        </td>
                        <td>
                          <button className="btn btn-ghost" style={{ padding: '6px 14px' }} onClick={() => setSelected(doc)}>
                            Examiner
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

      {selected && (
        <DocumentViewer
          doc={selected}
          onClose={() => setSelected(null)}
          onApprove={tab === 'pending' ? () => handleApprove(selected.id) : null}
          onReject={tab === 'pending' ? (reason) => handleReject(selected.id, reason) : null}
        />
      )}
    </>
  );
}
