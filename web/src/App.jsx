import React, { useState } from 'react';
import { 
  Download, 
  ShieldCheck, 
  Search, 
  Star, 
  Bell, 
  Heart, 
  Smartphone, 
  CheckCircle2, 
  AlertTriangle, 
  Clock, 
  UserCheck, 
  ClipboardList, 
  Award,
  ArrowRight,
  ExternalLink,
  ChevronDown,
  Info,
  Menu,
  X
} from 'lucide-react';

export default function App() {
  const [mobileMenuOpen, setMobileMenuOpen] = useState(false);

  const apkUrl = "/app-release.apk";

  return (
    <div className="landing-page">
      {/* ─── HEADER / NAVIGATION ─── */}
      <header className="site-header">
        <div className="container">
          <div className="nav-wrapper">
            <a href="#" className="logo-container">
              <img src="/logo.png" alt="FixerPro237 Logo" style={{ width: '42px', height: '42px', borderRadius: '12px', objectFit: 'contain', background: 'white', padding: '2px', border: '1px solid var(--border)' }} />
              <div className="logo-text">
                FixerPro237 <span>Cameroun</span>
              </div>
            </a>

            <nav>
              <ul className="nav-links">
                <li><a href="#problem" className="nav-link">Le Problème</a></li>
                <li><a href="#how-it-works" className="nav-link">Comment ça marche</a></li>
                <li><a href="#features" className="nav-link">Fonctionnalités</a></li>
                <li><a href="#instructions" className="nav-link">Installation</a></li>
              </ul>
            </nav>

            <div style={{ display: 'flex', alignItems: 'center', gap: '1rem' }}>
              <a href={apkUrl} download="FixerPro237-Cameroun.apk" className="btn-primary">
                <Download size={18} />
                <span>Télécharger l'APK</span>
              </a>
            </div>
          </div>
        </div>
      </header>

      {/* ─── HERO SECTION ─── */}
      <section className="hero-section">
        <div className="container">
          <div className="hero-grid">
            <div className="hero-content">
              <div className="badge-tag">
                <ShieldCheck size={16} />
                <span>Pilote Officiel — Yaoundé, Cameroun</span>
              </div>
              
              <h1 className="hero-title">
                La plateforme de confiance des <span>artisans qualifiés</span> au Cameroun
              </h1>
              
              <p className="hero-description">
                Décrivez votre problème et notre système intelligent vous assigne instantanément un artisan qualifié et vérifié. Suivez son arrivée en direct sur la carte !
              </p>

              <div className="hero-actions">
                <a href={apkUrl} download="FixerPro237-Cameroun.apk" className="btn-primary" style={{ padding: '1rem 2rem', fontSize: '1.05rem' }}>
                  <Download size={22} />
                  <span>Télécharger pour Android (59.1 MB)</span>
                </a>
                <a href="#how-it-works" className="btn-secondary">
                  <span>Découvrir le fonctionnement</span>
                </a>
              </div>

              <div className="hero-stats">
                <div className="stat-item">
                  <h4>100%</h4>
                  <p>Profils Vérifiés par Admin</p>
                </div>
                <div className="stat-item">
                  <h4>21+</h4>
                  <p>Catégories de Métiers</p>
                </div>
                <div className="stat-item">
                  <h4>0 FCFA</h4>
                  <p>Accès Gratuit pour Clients</p>
                </div>
              </div>
            </div>

            {/* Mobile App Mockup Preview */}
            <div className="phone-mockup-wrapper">
              <div className="phone-mockup">
                <div className="phone-screen">
                  {/* Top Bar */}
                  <div className="screen-header">
                    <div>
                      <div className="screen-app-title">FixerPro237</div>
                      <div style={{ fontSize: '0.75rem', color: 'var(--text-secondary)' }}>Yaoundé, Cameroun</div>
                    </div>
                    <div className="badge-verified" style={{ padding: '4px 10px', fontSize: '0.75rem' }}>
                      <CheckCircle2 size={12} /> Vérifié
                    </div>
                  </div>

                  {/* Technician Card Stand-in */}
                  <div className="screen-card">
                    <div style={{ display: 'flex', gap: '12px', alignItems: 'center', marginBottom: '10px' }}>
                      <div style={{ width: '48px', height: '48px', borderRadius: '50%', background: '#DBEAFE', display: 'flex', alignItems: 'center', justifyContent: 'center', fontWeight: 'bold', color: 'var(--primary)' }}>
                        SE
                      </div>
                      <div>
                        <div style={{ fontWeight: 'bold', fontSize: '0.95rem' }}>Samuel Électricien</div>
                        <div style={{ fontSize: '0.8rem', color: 'var(--text-secondary)' }}>Centre · Yaoundé</div>
                        <div style={{ display: 'flex', alignItems: 'center', gap: '4px', marginTop: '2px' }}>
                          <Star size={14} color="#F59E0B" fill="#F59E0B" />
                          <span style={{ fontSize: '0.8rem', fontWeight: 'bold' }}>4.85</span>
                          <span style={{ fontSize: '0.75rem', color: 'var(--text-secondary)' }}>(12 avis)</span>
                        </div>
                      </div>
                    </div>
                    <div style={{ background: 'var(--background)', padding: '8px 12px', borderRadius: '8px', fontSize: '0.8rem', color: 'var(--text-primary)' }}>
                      ⚡ Dépannage électrique rapide & câblage moderne.
                    </div>
                  </div>

                  {/* Service Request Workflow Preview */}
                  <div className="screen-card" style={{ borderLeft: '4px solid var(--primary)' }}>
                    <div style={{ fontSize: '0.75rem', fontWeight: 'bold', color: 'var(--primary)', marginBottom: '4px' }}>
                      DEMANDE EN COURS
                    </div>
                    <div style={{ fontSize: '0.85rem', fontWeight: '600' }}>Réparation tableau électrique</div>
                    <div style={{ display: 'flex', justifyContent: 'space-between', marginTop: '8px', fontSize: '0.75rem', color: 'var(--text-secondary)' }}>
                      <span>Statut: Acceptée</span>
                      <span style={{ color: 'var(--success)', fontWeight: 'bold' }}>En cours</span>
                    </div>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>
      </section>

      {/* ─── PROBLEM SECTION ─── */}
      <section id="problem" className="problem-section">
        <div className="container">
          <div className="section-header">
            <div className="badge-tag" style={{ background: '#FEE2E2', color: '#DC2626' }}>
              Le Constat Actuel
            </div>
            <h2 className="section-title">Pourquoi la recherche d'artisans au Cameroun est cassée</h2>
            <p className="section-subtitle">
              Aujourd'hui, trouver un dépanneur ou un artisan qualifié se fait de manière informelle et risquée.
            </p>
          </div>

          <div className="problem-grid">
            <div className="problem-card">
              <div className="problem-icon-box">
                <AlertTriangle size={26} />
              </div>
              <h3 style={{ fontSize: '1.25rem', fontWeight: '700', marginBottom: '0.75rem' }}>Aucune Vérification d'Identité</h3>
              <p style={{ color: 'var(--text-secondary)', fontSize: '0.95rem' }}>
                Faire entrer un inconnu chez soi via un groupe WhatsApp ou Facebook sans vérification préalable de sa pièce d'identité ou de sa compétence comporte d'importants risques de sécurité.
              </p>
            </div>

            <div className="problem-card">
              <div className="problem-icon-box">
                <Clock size={26} />
              </div>
              <h3 style={{ fontSize: '1.25rem', fontWeight: '700', marginBottom: '0.75rem' }}>Délais de Recherche Longs</h3>
              <p style={{ color: 'var(--text-secondary)', fontSize: '0.95rem' }}>
                Demander autour de soi ou parcourir des marchés physiques (Mvog-Ada, Briqueterie) prend des heures, sans aucune certitude de trouver la bonne personne disponible.
              </p>
            </div>

            <div className="problem-card">
              <div className="problem-icon-box">
                <Award size={26} />
              </div>
              <h3 style={{ fontSize: '1.25rem', fontWeight: '700', marginBottom: '0.75rem' }}>Avis Fictifs & Non Modérés</h3>
              <p style={{ color: 'var(--text-secondary)', fontSize: '0.95rem' }}>
                Les recommandations informelles manquent de transparence. Il n'existe aucun suivi historique du travail bien fait ni recours en cas de prestation bâclée.
              </p>
            </div>
          </div>
        </div>
      </section>

      {/* ─── HOW IT WORKS (SOLUTION) ─── */}
      <section id="how-it-works" className="steps-section">
        <div className="container">
          <div className="section-header">
            <div className="badge-tag">Dispatch Intelligent & Suivi GPS</div>
            <h2 className="section-title">Comment fonctionne FixerPro237 Cameroun</h2>
            <p className="section-subtitle">
              Une démarche structurée en 4 étapes pour une intervention rapide et sécurisée.
            </p>
          </div>

          <div className="steps-grid">
            <div className="step-card">
              <div className="step-number">1</div>
              <h3 style={{ fontSize: '1.15rem', fontWeight: '700', marginBottom: '0.5rem' }}>Décrire le Problème</h3>
              <p style={{ color: 'var(--text-secondary)', fontSize: '0.9rem' }}>
                Sélectionnez le métier, votre ville, et décrivez rapidement votre besoin.
              </p>
            </div>

            <div className="step-card">
              <div className="step-number">2</div>
              <h3 style={{ fontSize: '1.15rem', fontWeight: '700', marginBottom: '0.5rem' }}>Assignation Automatique</h3>
              <p style={{ color: 'var(--text-secondary)', fontSize: '0.9rem' }}>
                Le système trouve et notifie immédiatement les artisans disponibles et vérifiés de votre zone.
              </p>
            </div>

            <div className="step-card">
              <div className="step-number">3</div>
              <h3 style={{ fontSize: '1.15rem', fontWeight: '700', marginBottom: '0.5rem' }}>Suivi GPS en Direct</h3>
              <p style={{ color: 'var(--text-secondary)', fontSize: '0.9rem' }}>
                Dès qu'un artisan accepte, suivez son arrivée en temps réel sur la carte.
              </p>
            </div>

            <div className="step-card">
              <div className="step-number">4</div>
              <h3 style={{ fontSize: '1.15rem', fontWeight: '700', marginBottom: '0.5rem' }}>Évaluer le Service</h3>
              <p style={{ color: 'var(--text-secondary)', fontSize: '0.9rem' }}>
                Laissez une note uniquement après la fin effective de l'intervention.
              </p>
            </div>
          </div>
        </div>
      </section>

      {/* ─── KEY FEATURES ─── */}
      <section id="features" className="features-section">
        <div className="container">
          <div className="section-header">
            <div className="badge-tag">Fonctionnalités </div>
            <h2 className="section-title">La confiance au cœur du produit</h2>
            <p className="section-subtitle">
              Tout ce dont vous avez besoin pour trouver et gérer vos prestations en toute transparence.
            </p>
          </div>

          <div className="features-grid">
            <div className="card">
              <div className="feature-icon-box">
                <UserCheck size={24} />
              </div>
              <h3 style={{ fontSize: '1.2rem', fontWeight: '700', marginBottom: '0.5rem' }}>Badges d'Artisans Vérifiés</h3>
              <p style={{ color: 'var(--text-secondary)', fontSize: '0.925rem' }}>
                Chaque profil affichant la mention "Vérifié" a fait l'objet d'un contrôle manuel de sa pièce d'identité et de ses qualifications par notre équipe d'administration.
              </p>
            </div>

            <div className="card">
              <div className="feature-icon-box">
                <ClipboardList size={24} />
              </div>
              <h3 style={{ fontSize: '1.2rem', fontWeight: '700', marginBottom: '0.5rem' }}>Suivi des Demandes Structuré</h3>
              <p style={{ color: 'var(--text-secondary)', fontSize: '0.925rem' }}>
                Fini les messages WhatsApp éparpillés. Suivez chaque statut de mission clairement : En attente ➔ Acceptée ➔ En cours ➔ Terminée.
              </p>
            </div>

            <div className="card">
              <div className="feature-icon-box">
                <Star size={24} />
              </div>
              <h3 style={{ fontSize: '1.2rem', fontWeight: '700', marginBottom: '0.5rem' }}>Avis Légalement Garantis</h3>
              <p style={{ color: 'var(--text-secondary)', fontSize: '0.925rem' }}>
                Les notes de 1 à 5 étoiles ne peuvent être laissées qu'après la réalisation effective d'un travail confirmé sur l'application. Impossible de tricher.
              </p>
            </div>

            <div className="card">
              <div className="feature-icon-box">
                <Heart size={24} />
              </div>
              <h3 style={{ fontSize: '1.2rem', fontWeight: '700', marginBottom: '0.5rem' }}>Gestion des Favoris</h3>
              <p style={{ color: 'var(--text-secondary)', fontSize: '0.925rem' }}>
                Sauvegardez vos artisans préférés en un clic pour les retrouver immédiatement lors de vos prochains besoins domestiques ou professionnels.
              </p>
            </div>

            <div className="card">
              <div className="feature-icon-box">
                <Bell size={24} />
              </div>
              <h3 style={{ fontSize: '1.2rem', fontWeight: '700', marginBottom: '0.5rem' }}>Notifications In-App</h3>
              <p style={{ color: 'var(--text-secondary)', fontSize: '0.925rem' }}>
                Soyez notifié instantanément dans l'application dès que l'artisan accepte votre demande ou met à jour le statut de son intervention.
              </p>
            </div>

            <div className="card">
              <div className="feature-icon-box">
                <Smartphone size={24} />
              </div>
              <h3 style={{ fontSize: '1.2rem', fontWeight: '700', marginBottom: '0.5rem' }}>Optimisé pour Réseaux 3G</h3>
              <p style={{ color: 'var(--text-secondary)', fontSize: '0.925rem' }}>
                Conçu spécifiquement pour le contexte camerounais : chargements légers, pagination intelligente et consommation de données minimale.
              </p>
            </div>
          </div>
        </div>
      </section>

      {/* ─── DOWNLOAD & INSTALLATION SECTION ─── */}
      <section id="instructions" className="download-section">
        <div className="container">
          <div className="download-box">
            <div className="apk-badge-info">
              <Smartphone size={18} />
              <span>Version APK Officielle Android </span>
            </div>

            <h2>Téléchargez l'application maintenant</h2>
            <p>
              Installez directement l'application officielle sur votre smartphone Android et accédez au réseau d'artisans vérifiés de Yaoundé avec notre système de dispatch intelligent.
            </p>

            <a href={apkUrl} download="FixerPro237-Cameroun.apk" className="btn-primary" style={{ background: '#FFFFFF', color: 'var(--primary-dark)', fontSize: '1.1rem', padding: '1.1rem 2.5rem' }}>
              <Download size={24} color="var(--primary)" />
              <span style={{ fontWeight: '800' }}>Télécharger l'APK (59.1 MB)</span>
            </a>

            {/* Direct Install Instructions Box */}
            <div className="install-instructions">
              <div className="instructions-header">
                <Info size={24} color="var(--accent-gold)" />
                <h3 style={{ fontSize: '1.2rem', fontWeight: '700', color: 'white' }}>
                  Comment installer l'APK sur votre téléphone Android
                </h3>
              </div>

              <div className="instructions-list">
                <div className="instruction-step">
                  <div className="step-bullet">1</div>
                  <div>
                    <strong>Téléchargez le fichier APK :</strong> Cliquez sur le bouton ci-dessus depuis le navigateur de votre téléphone.
                  </div>
                </div>

                <div className="instruction-step">
                  <div className="step-bullet">2</div>
                  <div>
                    <strong>Autorisez les sources inconnues :</strong> Si Android affiche un avertissement, allez dans <em>Paramètres ➔ Sécurité (ou Applications) ➔ Installer des applications inconnues</em> et autorisez votre navigateur (Chrome/Edge).
                  </div>
                </div>

                <div className="instruction-step">
                  <div className="step-bullet">3</div>
                  <div>
                    <strong>Installez et ouvrez :</strong> Ouvrez le fichier <code>app-release.apk</code> téléchargé dans votre dossier Téléchargements et appuyez sur <em>Installer</em>.
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>
      </section>

      {/* ─── FOOTER ─── */}
      <footer className="site-footer">
        <div className="container">
          <div className="footer-grid">
            <div className="footer-brand">
              <div className="logo-container">
                <div className="logo-icon" style={{ width: '36px', height: '36px' }}>
                  <ShieldCheck size={20} />
                </div>
                <div className="logo-text" style={{ color: 'white', fontSize: '1.2rem' }}>
                  FixerPro237 <span>Cameroun</span>
                </div>
              </div>
              <p>
                Plateforme de dispatch intelligent et de vérification d'artisans au Cameroun. Projet Pilote — Yaoundé 2026.
              </p>
            </div>

            <div>
              <h4 className="footer-heading">Navigation</h4>
              <ul className="footer-links">
                <li><a href="#problem">Le Constat</a></li>
                <li><a href="#how-it-works">Fonctionnement</a></li>
                <li><a href="#features">Fonctionnalités</a></li>
                <li><a href="#instructions">Guide d'installation</a></li>
              </ul>
            </div>

            <div>
              <h4 className="footer-heading">Projet</h4>
              <ul className="footer-links">
                <li><span>Projet de Fin d'Études (bachelor degree)</span></li>
                <li><span>Ville pilote : Yaoundé</span></li>
                <li><span>Statut : MVP V1 </span></li>
              </ul>
            </div>
          </div>

          <div className="footer-bottom">
            <p>&copy; 2026 FixerPro237 Cameroun. Tous droits réservés.</p>
          </div>
        </div>
      </footer>
    </div>
  );
}
