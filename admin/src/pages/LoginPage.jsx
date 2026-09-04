import { useState } from 'react';
import { useNavigate, useLocation } from 'react-router-dom';
import { useAuth } from '../context/AuthContext';
import { Mail, Lock, AlertCircle, Eye, EyeOff } from 'lucide-react';

export default function LoginPage() {
  const { login } = useAuth();
  const navigate = useNavigate();
  const location = useLocation();

  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [showPw, setShowPw] = useState(false);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');

  const from = location.state?.from?.pathname || '/';

  const handleSubmit = async (e) => {
    e.preventDefault();
    setError('');
    setLoading(true);
    try {
      await login(email, password);
      navigate(from, { replace: true });
    } catch (err) {
      setError(err.response?.data?.message || err.message || 'Identifiants administrateur incorrects');
    } finally {
      setLoading(false);
    }
  };

  const handleQuickFill = () => {
    setEmail('admin@fixerpro237.cm');
    setPassword('Password123!');
    setError('');
  };

  return (
    <div className="simple-login-page">
      <div className="simple-login-card">
        {/* Logo & Header */}
        <div className="simple-login-header">
          <div className="simple-login-logo">
            <img src="/logo.png" alt="FixerPro237" />
          </div>
          <h1 className="simple-login-brand">
            FixerPro<span>237</span>
          </h1>
          <span className="simple-login-tag">Espace Administration</span>
          <p className="simple-login-subtitle">
            Connectez-vous pour accéder au tableau de bord
          </p>
        </div>

        {/* Error alert */}
        {error && (
          <div className="simple-login-error">
            <AlertCircle size={16} />
            <span>{error}</span>
          </div>
        )}

        {/* Form */}
        <form className="simple-login-form" onSubmit={handleSubmit}>
          <div className="simple-form-group">
            <label htmlFor="email">Adresse Email</label>
            <div className="simple-input-wrapper">
              <Mail size={20} className="simple-input-icon" />
              <input
                id="email"
                type="email"
                placeholder="admin@fixerpro237.cm"
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                required
                autoComplete="email"
              />
            </div>
          </div>

          <div className="simple-form-group">
            <label htmlFor="password">Mot de passe</label>
            <div className="simple-input-wrapper">
              <Lock size={20} className="simple-input-icon" />
              <input
                id="password"
                type={showPw ? 'text' : 'password'}
                placeholder="••••••••"
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                required
                autoComplete="current-password"
              />
              <button
                type="button"
                className="simple-pw-toggle"
                onClick={() => setShowPw(!showPw)}
                tabIndex={-1}
                aria-label="Afficher ou masquer le mot de passe"
              >
                {showPw ? <EyeOff size={20} /> : <Eye size={20} />}
              </button>
            </div>
          </div>

          <button
            type="submit"
            className="simple-submit-btn"
            disabled={loading}
          >
            {loading ? <span className="simple-spinner" /> : 'Se connecter'}
          </button>
        </form>

        {/* Quick test credentials */}
        <div className="simple-demo-box">
          <span>Compte de test :</span>
          <button type="button" onClick={handleQuickFill}>
            Remplir automatiquement
          </button>
        </div>

        {/* Footer */}
        <div className="simple-login-footer">
          FixerPro237 Cameroun • Portail Sécurisé
        </div>
      </div>
    </div>
  );
}
