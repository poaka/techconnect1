export default function StatCard({ label, value, icon: Icon, color, onClick }) {
  return (
    <div className="stat-card" onClick={onClick} style={{ cursor: onClick ? 'pointer' : 'default' }}>
      <div
        className="stat-icon"
        style={{ background: `${color}1A`, color: color }}
      >
        <Icon size={22} />
      </div>
      <div>
        <div className="stat-value">{value ?? '—'}</div>
        <div className="stat-label">{label}</div>
      </div>
    </div>
  );
}
