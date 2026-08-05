import { NavLink, useNavigate } from 'react-router-dom';
import {
  LayoutDashboard, ShieldCheck, Users, Wrench,
  ClipboardList, Flag, Tag, Map, LogOut
} from 'lucide-react';
import { useAuth } from '../context/AuthContext';

const navItems = [
  { label: 'Vue d\'ensemble', to: '/', icon: LayoutDashboard },
  { section: 'Modération' },
  { label: 'Vérifications', to: '/verifications', icon: ShieldCheck },
  { label: 'Signalements', to: '/reports', icon: Flag },
  { section: 'Utilisateurs' },
  { label: 'Tous les Utilisateurs', to: '/users', icon: Users },
  { label: 'Techniciens', to: '/technicians', icon: Wrench },
  { section: 'Contenu' },
  { label: 'Demandes de Service', to: '/requests', icon: ClipboardList },
  { label: 'Catégories', to: '/categories', icon: Tag },
  { label: 'Régions & Villes', to: '/regions', icon: Map },
];

export default function Sidebar() {
  const { user, logout } = useAuth();
  const navigate = useNavigate();

  const handleLogout = () => {
    logout();
    navigate('/login');
  };

  const initials = user?.full_name
    ? user.full_name.split(' ').map(n => n[0]).join('').slice(0, 2).toUpperCase()
    : 'AD';

  return (
    <aside className="sidebar">
      {/* Logo */}
      <div className="sidebar-logo">
        <img src="/logo.png" alt="TechConnect Logo" />
        <div className="sidebar-logo-text">
          <span className="sidebar-logo-title">TechConnect</span>
          <span className="sidebar-logo-sub">Administration</span>
        </div>
      </div>

      {/* Nav */}
      <nav className="sidebar-nav">
        {navItems.map((item, i) =>
          item.section ? (
            <div key={i} className="sidebar-section-label">{item.section}</div>
          ) : (
            <NavLink
              key={item.to}
              to={item.to}
              end={item.to === '/'}
              className={({ isActive }) =>
                `sidebar-link${isActive ? ' active' : ''}`
              }
            >
              <item.icon size={17} />
              {item.label}
            </NavLink>
          )
        )}
      </nav>

      {/* User footer */}
      <div className="sidebar-footer">
        <div className="sidebar-user">
          <div className="sidebar-user-avatar">{initials}</div>
          <div className="sidebar-user-info">
            <div className="sidebar-user-name">{user?.full_name || 'Admin'}</div>
            <div className="sidebar-user-role">Administrateur</div>
          </div>
          <button className="btn-logout" onClick={handleLogout} title="Se déconnecter">
            <LogOut size={16} />
          </button>
        </div>
      </div>
    </aside>
  );
}
