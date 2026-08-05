import { useState, useEffect } from 'react';
import { Wrench, Star } from 'lucide-react';
import Header from '../components/Header';
import apiClient from '../api/client';

export default function TechniciansPage() {
  const [techs, setTechs] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');

  const fetchTechs = () => {
    setLoading(true);
    setError('');
    apiClient.get('/admin/technicians')
      .then(res => setTechs(res.data.data || []))
      .catch(() => setError('Impossible de charger les techniciens.'))
      .finally(() => setLoading(false));
  };

  useEffect(() => { fetchTechs(); }, []);

  return (
    <>
      <Header title="Techniciens" subtitle={`${techs.length} technicien(s) enregistré(s)`} onRefresh={fetchTechs} />
      <div className="page-body">
        <div className="card">
          {loading ? (
            <div className="loading-box"><div className="spinner" /></div>
          ) : error ? (
            <div className="empty-state"><p className="text-error">{error}</p></div>
          ) : techs.length === 0 ? (
            <div className="empty-state">
              <div className="empty-icon"><Wrench size={28} style={{ color: 'var(--text-secondary)' }} /></div>
              <p className="font-semibold">Aucun technicien trouvé</p>
            </div>
          ) : (
            <div className="table-wrapper">
              <table>
                <thead>
                  <tr>
                    <th>Technicien</th>
                    <th>Email</th>
                    <th>Ville</th>
                    <th>Catégories</th>
                    <th>Tarif (FCFA)</th>
                    <th>Note</th>
                    <th>Statut</th>
                    <th>Disponibilité</th>
                  </tr>
                </thead>
                <tbody>
                  {techs.map(tech => {
                    const user = tech.user || {};
                    const city = tech.city || {};
                    const categories = tech.categories || [];
                    return (
                      <tr key={tech.id}>
                        <td>
                          <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
                            <div className="avatar">
                              {user.avatar_url
                                ? <img src={user.avatar_url} alt="" />
                                : (user.full_name?.[0]?.toUpperCase() || '?')
                              }
                            </div>
                            <div>
                              <div className="font-semibold">{user.full_name || '—'}</div>
                              <div className="text-xs text-secondary">{user.phone || ''}</div>
                            </div>
                          </div>
                        </td>
                        <td className="text-secondary">{user.email || '—'}</td>
                        <td className="text-secondary">{city.name || '—'}</td>
                        <td>
                          <div style={{ display: 'flex', gap: 4, flexWrap: 'wrap' }}>
                            {categories.slice(0, 2).map((c, i) => (
                              <span key={i} className="badge-pill admin" style={{ fontSize: '0.7rem', padding: '2px 8px' }}>
                                {c.category?.name || c.name}
                              </span>
                            ))}
                            {categories.length > 2 && (
                              <span className="text-xs text-secondary">+{categories.length - 2}</span>
                            )}
                          </div>
                        </td>
                        <td className="text-secondary">
                          {tech.price_min && tech.price_max
                            ? `${Number(tech.price_min).toLocaleString()} – ${Number(tech.price_max).toLocaleString()}`
                            : '—'
                          }
                        </td>
                        <td>
                          {tech.rating_avg > 0 ? (
                            <span style={{ display: 'flex', alignItems: 'center', gap: 4 }}>
                              <Star size={13} fill="#F59E0B" stroke="#F59E0B" />
                              {Number(tech.rating_avg).toFixed(1)}
                              <span className="text-xs text-secondary">({tech.rating_count})</span>
                            </span>
                          ) : '—'}
                        </td>
                        <td>
                          <span className={`badge-pill ${tech.verified ? 'approved' : 'pending'}`}>
                            {tech.verified ? 'Vérifié' : 'Non vérifié'}
                          </span>
                        </td>
                        <td>
                          <span className={`badge-pill ${tech.availability === 'available' ? 'approved' : 'warning'}`}>
                            {tech.availability === 'available' ? 'Disponible' : 'Indisponible'}
                          </span>
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
