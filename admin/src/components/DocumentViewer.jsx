import { X, ZoomIn, FileText } from 'lucide-react';

export default function DocumentViewer({ doc, onClose, onApprove, onReject }) {
  const fileUrl = doc?.file_url || '';
  const isPdf = fileUrl.toLowerCase().endsWith('.pdf');

  return (
    <div className="modal-overlay" onClick={onClose}>
      <div className="modal-box wide" onClick={e => e.stopPropagation()}>
        <div className="modal-header">
          <div>
            <h2 className="modal-title">
              Vérification: {doc?.document_type?.toUpperCase()}
            </h2>
            {doc?.technician && (
              <p className="text-sm text-secondary" style={{ marginTop: 4 }}>
                {doc.technician.full_name} — {doc.technician.email}
              </p>
            )}
          </div>
          <button className="btn-icon" onClick={onClose}><X size={20} /></button>
        </div>

        <div className="modal-body">
          {/* Technician Info */}
          {doc?.technician && (
            <div style={{
              background: 'var(--surface-2)',
              borderRadius: 'var(--radius-md)',
              padding: '14px 16px',
              display: 'grid',
              gridTemplateColumns: '1fr 1fr',
              gap: '8px',
              fontSize: '0.875rem',
            }}>
              <div><span className="text-secondary">Nom: </span><strong>{doc.technician.user?.full_name || 'Inconnu'}</strong></div>
              <div><span className="text-secondary">Email: </span>{doc.technician.user?.email || 'N/A'}</div>
              <div><span className="text-secondary">Ville: </span>{doc.technician.city?.name || 'N/A'}</div>
              <div>
                <span className="text-secondary">Soumis le: </span>
                {doc.uploaded_at ? new Date(doc.uploaded_at).toLocaleDateString('fr-FR', { day: '2-digit', month: 'short', year: 'numeric' }) : 'N/A'}
              </div>
            </div>
          )}

          {/* Document Preview */}
          <div className="doc-preview-box">
            {isPdf ? (
              <div style={{ textAlign: 'center', color: '#94a3b8', padding: '40px' }}>
                <FileText size={64} style={{ marginBottom: 12, color: '#ef4444' }} />
                <p style={{ fontWeight: 600, color: 'white' }}>Document PDF</p>
                <a
                  href={fileUrl}
                  target="_blank"
                  rel="noopener noreferrer"
                  className="btn btn-ghost"
                  style={{ marginTop: 16, color: 'white', border: '1px solid rgba(255,255,255,0.2)' }}
                >
                  Ouvrir le PDF
                </a>
              </div>
            ) : fileUrl ? (
              <a href={fileUrl} target="_blank" rel="noopener noreferrer" style={{ display: 'block', position: 'relative' }}>
                <img
                  src={fileUrl}
                  alt="Document"
                  onError={e => {
                    e.target.style.display = 'none';
                    e.target.nextSibling.style.display = 'flex';
                  }}
                />
                <div style={{
                  display: 'none', flexDirection: 'column', alignItems: 'center',
                  color: '#94a3b8', padding: 40, gap: 12
                }}>
                  <ZoomIn size={48} />
                  <p>Aperçu indisponible</p>
                  <p style={{ fontSize: '0.75rem', wordBreak: 'break-all', maxWidth: 300 }}>{fileUrl}</p>
                </div>
                <div style={{
                  position: 'absolute', bottom: 8, right: 8,
                  background: 'rgba(0,0,0,0.6)', borderRadius: 20,
                  padding: '4px 12px', display: 'flex', alignItems: 'center', gap: 6,
                  color: 'white', fontSize: '0.75rem',
                }}>
                  <ZoomIn size={13} /> Cliquer pour agrandir
                </div>
              </a>
            ) : (
              <div style={{ color: '#94a3b8', textAlign: 'center', padding: 40 }}>
                <FileText size={48} style={{ marginBottom: 12 }} />
                <p>Aucun fichier joint</p>
              </div>
            )}
          </div>

          {/* Rejection reason input if rejecting */}
          {onReject && (
            <RejectionSection onApprove={onApprove} onReject={onReject} />
          )}
        </div>
      </div>
    </div>
  );
}

function RejectionSection({ onApprove, onReject }) {
  const [isRejecting, setIsRejecting] = React.useState(false);
  const [reason, setReason] = React.useState('');

  return (
    <div>
      {isRejecting && (
        <div className="form-group" style={{ marginBottom: 16 }}>
          <label className="form-label">Motif du rejet *</label>
          <textarea
            className="form-textarea"
            placeholder="Ex: Document flou, expiré, non conforme..."
            value={reason}
            onChange={e => setReason(e.target.value)}
          />
        </div>
      )}
      <div style={{ display: 'flex', gap: 12 }}>
        {!isRejecting ? (
          <>
            <button
              className="btn btn-ghost"
              style={{ flex: 1, justifyContent: 'center', color: 'var(--error)', borderColor: 'var(--error)' }}
              onClick={() => setIsRejecting(true)}
            >
              Rejeter
            </button>
            <button
              className="btn btn-success"
              style={{ flex: 1, justifyContent: 'center' }}
              onClick={onApprove}
            >
              Approuver
            </button>
          </>
        ) : (
          <>
            <button
              className="btn btn-ghost"
              style={{ flex: 1, justifyContent: 'center' }}
              onClick={() => setIsRejecting(false)}
            >
              Annuler
            </button>
            <button
              className="btn btn-danger"
              style={{ flex: 1, justifyContent: 'center' }}
              onClick={() => reason.trim() && onReject(reason)}
              disabled={!reason.trim()}
            >
              Confirmer le rejet
            </button>
          </>
        )}
      </div>
    </div>
  );
}

import React from 'react';
