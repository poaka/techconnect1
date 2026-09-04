# FixerPro237 Cameroun

FixerPro237 est une plateforme de mise en relation entre clients et artisans locaux au Cameroun, basée sur un système de **Dispatch Intelligent**. 

Le système ne fonctionne pas comme un annuaire classique (où le client doit chercher, appeler et espérer une réponse). Ici, le client exprime son besoin (Catégorie, Ville), et le backend se charge d'alerter les techniciens disponibles, vérifiés et à proximité. Le premier technicien à accepter l'offre obtient le chantier.

## Stack Technologique

- **Backend** : Node.js (Express.js)
- **Base de données** : PostgreSQL hébergé sur Supabase
- **Mobile** : Flutter (Riverpod, GoRouter, Dio, Geolocator)
- **Web (Admin/Basique)** : React (Vite)

## Structure du dépôt

- `/backend` : Code source de l'API Node.js.
- `/mobile` : Code source de l'application Flutter.
- `/database` : Schémas SQL et données de test (Supabase).
- `/documentation` : (Obsolète) Anciennes maquettes et spécifications.

## Lancement rapide

### 1. Variables d'environnement
Créez un `.env` dans `/backend` en copiant `.env.example`.
Renseignez vos clés Supabase et le port (5000 par défaut).

### 2. Démarrer le Backend
```bash
cd backend
npm install
npm run dev
```

### 3. Démarrer l'application Mobile
Assurez-vous que l'URL de base dans le `DioClient` (`mobile/lib/core/network/dio_client.dart`) pointe vers l'adresse IP de votre machine (ex: `http://192.168.1.X:5000/api`).
```bash
cd mobile
flutter pub get
flutter run
```

## Documentation Complète
- [Roadmap & Fonctionnalités](roadmap.md)
- [Guide Backend](backend/BACKEND_DOCS.md)
- [Guide Mobile](mobile/MOBILE_DOCS.md)
- [Guide IA (Contexte de développement)](AI-agent-guide.md)
