import { useState, useEffect } from 'react';
import { Plus, Pencil, Trash2, Map, ChevronDown, ChevronRight } from 'lucide-react';
import Header from '../components/Header';
import apiClient from '../api/client';

export default function RegionsPage() {
  const [regions, setRegions] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [expanded, setExpanded] = useState({});
  const [regionModal, setRegionModal] = useState(null); // null | 'create' | region
  const [cityModal, setCityModal] = useState(null); // null | 'create' | city
  const [cityParentId, setCityParentId] = useState(null);
  const [deleteTarget, setDeleteTarget] = useState(null); // { type: 'region'|'city', item }
  const [regionForm, setRegionForm] = useState({ name: '' });
  const [cityForm, setCityForm] = useState({ name: '', regionId: '' });
  const [saving, setSaving] = useState(false);

  const fetchRegions = () => {
    setLoading(true);
    setError('');
    apiClient.get('/admin/regions')
      .then(res => setRegions(res.data.data || []))
      .catch(() => setError('Impossible de charger les régions.'))
      .finally(() => setLoading(false));
  };

  useEffect(() => { fetchRegions(); }, []);

  const toggleExpand = (id) => setExpanded(e => ({ ...e, [id]: !e[id] }));

  // Region actions
  const openCreateRegion = () => { setRegionForm({ name: '' }); setRegionModal('create'); };
  const openEditRegion = (r) => { setRegionForm({ name: r.name }); setRegionModal(r); };

  const handleSaveRegion = async () => {
    if (!regionForm.name.trim()) return;
    setSaving(true);
    try {
      if (regionModal === 'create') {
        await apiClient.post('/admin/regions', { name: regionForm.name });
      } else {
        await apiClient.put(`/admin/regions/${regionModal.id}`, { name: regionForm.name });
      }
      setRegionModal(null);
      fetchRegions();
    } catch { alert('Erreur.'); } finally { setSaving(false); }
  };

  // City actions
  const openCreateCity = (regionId) => { setCityForm({ name: '', regionId }); setCityParentId(regionId); setCityModal('create'); };
  const openEditCity = (city, regionId) => { setCityForm({ name: city.name, regionId }); setCityParentId(regionId); setCityModal(city); };

  const handleSaveCity = async () => {
    if (!cityForm.name.trim()) return;
    setSaving(true);
    try {
      if (cityModal === 'create') {
        await apiClient.post('/admin/cities', { name: cityForm.name, regionId: cityParentId });
      } else {
        await apiClient.put(`/admin/cities/${cityModal.id}`, { name: cityForm.name, regionId: cityParentId });
      }
      setCityModal(null);
      fetchRegions();
    } catch { alert('Erreur.'); } finally { setSaving(false); }
  };

  // Delete
  const handleDelete = async () => {
    if (!deleteTarget) return;
    try {
      if (deleteTarget.type === 'region') {
        await apiClient.delete(`/admin/regions/${deleteTarget.item.id}`);
      } else {
        await apiClient.delete(`/admin/cities/${deleteTarget.item.id}`);
      }
      setDeleteTarget(null);
      fetchRegions();
    } catch { alert('Erreur lors de la suppression.'); }
  };

  return (
    <>
      <Header title="Régions & Villes" subtitle="Gérer les zones géographiques couvertes par TechConnect" onRefresh={fetchRegions} />
      <div className="page-body">
        <div className="page-header">
          <div />
          <button className="btn btn-primary" onClick={openCreateRegion}>
            <Plus size={16} /> Nouvelle région
          </button>
        </div>

        {loading ? (
          <div className="loading-box"><div className="spinner" /></div>
        ) : error ? (
          <div className="empty-state"><p className="text-error">{error}</p></div>
        ) : regions.length === 0 ? (
          <div className="empty-state">
            <div className="empty-icon"><Map size={28} style={{ color: 'var(--text-secondary)' }} /></div>
            <p className="font-semibold">Aucune région</p>
            <button className="btn btn-primary" onClick={openCreateRegion}><Plus size={14} /> Créer la première</button>
          </div>
        ) : (
          <div style={{ display: 'flex', flexDirection: 'column', gap: 12 }}>
            {regions.map(region => (
              <div key={region.id} className="card">
                {/* Region row */}
                <div
                  style={{ display: 'flex', alignItems: 'center', padding: '16px 20px', cursor: 'pointer', gap: 10 }}
                  onClick={() => toggleExpand(region.id)}
                >
                  <span style={{ color: 'var(--text-secondary)' }}>
                    {expanded[region.id] ? <ChevronDown size={18} /> : <ChevronRight size={18} />}
                  </span>
                  <Map size={18} style={{ color: 'var(--primary)' }} />
                  <span className="font-bold" style={{ flex: 1, fontSize: '1rem' }}>{region.name}</span>
                  <span className="text-sm text-secondary" style={{ marginRight: 8 }}>
                    {region.cities?.length || 0} ville(s)
                  </span>
                  <div style={{ display: 'flex', gap: 4 }} onClick={e => e.stopPropagation()}>
                    <button className="btn-icon" onClick={() => openEditRegion(region)}><Pencil size={14} /></button>
                    <button className="btn-icon danger" onClick={() => setDeleteTarget({ type: 'region', item: region })}><Trash2 size={14} /></button>
                    <button className="btn btn-ghost" style={{ padding: '5px 12px', fontSize: '0.8rem' }} onClick={() => openCreateCity(region.id)}>
                      <Plus size={13} /> Ville
                    </button>
                  </div>
                </div>

                {/* Cities list */}
                {expanded[region.id] && (
                  <div style={{ borderTop: '1px solid var(--border)' }}>
                    {(region.cities || []).length === 0 ? (
                      <div className="empty-state" style={{ padding: '20px' }}>
                        <p className="text-sm text-secondary">Aucune ville — ajoutez-en une !</p>
                      </div>
                    ) : (
                      (region.cities || []).map(city => (
                        <div
                          key={city.id}
                          style={{
                            display: 'flex', alignItems: 'center', padding: '12px 20px 12px 48px',
                            borderBottom: '1px solid var(--border)', gap: 10,
                          }}
                        >
                          <span style={{ flex: 1, fontSize: '0.9rem' }}>📍 {city.name}</span>
                          <button className="btn-icon" onClick={() => openEditCity(city, region.id)}><Pencil size={13} /></button>
                          <button className="btn-icon danger" onClick={() => setDeleteTarget({ type: 'city', item: city })}><Trash2 size={13} /></button>
                        </div>
                      ))
                    )}
                  </div>
                )}
              </div>
            ))}
          </div>
        )}
      </div>

      {/* Region Modal */}
      {regionModal && (
        <div className="modal-overlay" onClick={() => setRegionModal(null)}>
          <div className="modal-box" onClick={e => e.stopPropagation()} style={{ maxWidth: 400 }}>
            <div className="modal-header">
              <h2 className="modal-title">{regionModal === 'create' ? 'Nouvelle région' : 'Modifier la région'}</h2>
              <button className="btn-icon" onClick={() => setRegionModal(null)}>✕</button>
            </div>
            <div className="modal-body">
              <div className="form-group">
                <label className="form-label">Nom de la région *</label>
                <input className="form-input" value={regionForm.name} onChange={e => setRegionForm({ name: e.target.value })} placeholder="ex: Centre" />
              </div>
            </div>
            <div className="modal-footer">
              <button className="btn btn-ghost" onClick={() => setRegionModal(null)}>Annuler</button>
              <button className="btn btn-primary" onClick={handleSaveRegion} disabled={saving || !regionForm.name.trim()}>
                {saving ? '...' : 'Enregistrer'}
              </button>
            </div>
          </div>
        </div>
      )}

      {/* City Modal */}
      {cityModal && (
        <div className="modal-overlay" onClick={() => setCityModal(null)}>
          <div className="modal-box" onClick={e => e.stopPropagation()} style={{ maxWidth: 400 }}>
            <div className="modal-header">
              <h2 className="modal-title">{cityModal === 'create' ? 'Nouvelle ville' : 'Modifier la ville'}</h2>
              <button className="btn-icon" onClick={() => setCityModal(null)}>✕</button>
            </div>
            <div className="modal-body">
              <div className="form-group">
                <label className="form-label">Nom de la ville *</label>
                <input className="form-input" value={cityForm.name} onChange={e => setCityForm(f => ({ ...f, name: e.target.value }))} placeholder="ex: Douala" />
              </div>
            </div>
            <div className="modal-footer">
              <button className="btn btn-ghost" onClick={() => setCityModal(null)}>Annuler</button>
              <button className="btn btn-primary" onClick={handleSaveCity} disabled={saving || !cityForm.name.trim()}>
                {saving ? '...' : 'Enregistrer'}
              </button>
            </div>
          </div>
        </div>
      )}

      {/* Delete Confirm */}
      {deleteTarget && (
        <div className="modal-overlay" onClick={() => setDeleteTarget(null)}>
          <div className="modal-box" onClick={e => e.stopPropagation()} style={{ maxWidth: 400 }}>
            <div className="modal-header">
              <h2 className="modal-title">Supprimer {deleteTarget.type === 'region' ? 'la région' : 'la ville'} ?</h2>
            </div>
            <div className="modal-body">
              <p>Voulez-vous vraiment supprimer <strong>"{deleteTarget.item.name}"</strong> ?</p>
              {deleteTarget.type === 'region' && (
                <p className="text-sm text-error" style={{ marginTop: 8 }}>⚠️ Toutes les villes de cette région seront également supprimées.</p>
              )}
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
