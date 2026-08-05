import { RefreshCw } from 'lucide-react';

export default function Header({ title, subtitle, onRefresh }) {
  return (
    <header className="admin-header">
      <div>
        <h1 className="header-title">{title}</h1>
        {subtitle && <p className="text-sm text-secondary" style={{ marginTop: 2 }}>{subtitle}</p>}
      </div>
      <div className="header-right">
        {onRefresh && (
          <button className="btn btn-ghost" onClick={onRefresh} style={{ padding: '7px 14px' }}>
            <RefreshCw size={15} />
            Actualiser
          </button>
        )}
      </div>
    </header>
  );
}
