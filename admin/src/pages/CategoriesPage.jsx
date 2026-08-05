import { useState, useEffect } from 'react';
import { Plus, Pencil, Trash2, Tag } from 'lucide-react';
import Header from '../components/Header';
import apiClient from '../api/client';

export default function CategoriesPage() {
  const [categories, setCategories] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [modal, setModal] = useState(null); // null | 'create' | category object
  const [deleteTarget, setDeleteTarget] = useState(null);
  const [form, setForm] = useState({ name: '', description: '', icon: '' });
  const [saving, setSaving] = useState(false);

  const fetchCategories = () => {
    setLoading(true);
    setError('');
    apiClient.get('/admin/categories')
      .then(res => setCategories(res.data.data || []))
      .catch(() => setError('Impossible de charger les catégories.'))
      .finally(() => setLoading(false));
  };

  useEffect(() => { fetchCategories(); }, []);

  const openCreate = () => {
    setForm({ name: '', description: '', icon: '' });
    setModal('create');
  };

  const openEdit = (cat) => {
    setForm({ name: cat.name || '', description: cat.description || '', icon: cat.icon_name || cat.icon || '' });
    setModal(cat);
  };

  const handleSave = async () => {
    if (!form.name.trim()) return;
    setSaving(true);
    try {
      const payload = { name: form.name.trim(), description: form.description.trim(), icon: form.icon.trim() };
      if (modal === 'create') {
        await apiClient.post('/admin/categories', payload);
      } else {
        await apiClient.put(`/admin/categories/${modal.id}`, payload);
      }
      setModal(null);
      fetchCategories();
    } catch {
      alert('Erreur lors de la sauvegarde.');
    } finally {
      setSaving(false);
    }
  };

  const handleDelete = async () => {
    if (!deleteTarget) return;
    try {
      await apiClient.delete(`/admin/categories/${deleteTarget.id}`);
      setDeleteTarget(null);
      fetchCategories();
    } catch {
      alert('Erreur lors de la suppression.');
    }
  };

  return (
    <>
      <Header title="Catégories de Services" subtitle="Gérer les catégories disponibles dans l'application" onRefresh={fetchCategories} />
      <div className="page-body">
        <div className="page-header">
          <div />
          <button className="btn btn-primary" onClick={openCreate}>
            <Plus size={16} /> Nouvelle catégorie
          </button>
        </div>

        <div className="card">
          {loading ? (
            <div className="loading-box"><div className="spinner" /></div>
          ) : error ? (
            <div className="empty-state"><p className="text-error">{error}</p></div>
          ) : categories.length === 0 ? (
            <div className="empty-state">
              <div className="empty-icon"><Tag size={28} style={{ color: 'var(--text-secondary)' }} /></div>
              <p className="font-semibold">Aucune catégorie</p>
              <button className="btn btn-primary" onClick={openCreate}><Plus size={14} /> Créer la première</button>
            </div>
          ) : (
            <div className="table-wrapper">
              <table>
                <thead>
                  <tr>
                    <th>Icône</th>
                    <th>Nom</th>
                    <th>Description</th>
                    <th>Actions</th>
                  </tr>
                </thead>
                <tbody>
                  {categories.map(cat => (
                    <tr key={cat.id}>
                      <td style={{ fontSize: 26 }}>{cat.icon_name || cat.icon || '📁'}</td>
                      <td className="font-semibold">{cat.name}</td>
                      <td className="text-secondary">{cat.description || '—'}</td>
                      <td>
                        <div style={{ display: 'flex', gap: 4 }}>
                          <button className="btn-icon" onClick={() => openEdit(cat)} title="Modifier"><Pencil size={15} /></button>
                          <button className="btn-icon danger" onClick={() => setDeleteTarget(cat)} title="Supprimer"><Trash2 size={15} /></button>
                        </div>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          )}
        </div>
      </div>

      {/* Create/Edit Modal */}
      {modal && (
        <div className="modal-overlay" onClick={() => setModal(null)}>
          <div className="modal-box" onClick={e => e.stopPropagation()}>
            <div className="modal-header">
              <h2 className="modal-title">{modal === 'create' ? 'Nouvelle catégorie' : 'Modifier la catégorie'}</h2>
              <button className="btn-icon" onClick={() => setModal(null)}>✕</button>
            </div>
            <div className="modal-body">
              <div className="form-group">
                <label className="form-label">Nom *</label>
                <input className="form-input" value={form.name} onChange={e => setForm(f => ({ ...f, name: e.target.value }))} placeholder="ex: Plomberie" />
              </div>
              <div className="form-group">
                <label className="form-label">Description</label>
                <textarea className="form-textarea" value={form.description} onChange={e => setForm(f => ({ ...f, description: e.target.value }))} placeholder="Courte description..." />
              </div>
              <div className="form-group">
                <label className="form-label">Emoji / Icône</label>
                <input className="form-input" value={form.icon} onChange={e => setForm(f => ({ ...f, icon: e.target.value }))} placeholder="ex: 🔧" maxLength={4} style={{ fontSize: 20, width: 80 }} />
              </div>
            </div>
            <div className="modal-footer">
              <button className="btn btn-ghost" onClick={() => setModal(null)}>Annuler</button>
              <button className="btn btn-primary" onClick={handleSave} disabled={saving || !form.name.trim()}>
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
            <div className="modal-header"><h2 className="modal-title">Supprimer la catégorie ?</h2></div>
            <div className="modal-body"><p>Voulez-vous vraiment supprimer <strong>"{deleteTarget.name}"</strong> ?</p></div>
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
