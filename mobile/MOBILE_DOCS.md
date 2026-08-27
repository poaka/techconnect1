# Documentation Mobile - FixerPro237

L'application Mobile (Flutter) est l'interface principale pour les Clients et les Techniciens.

## Architecture & Librairies
- **State Management** : `flutter_riverpod` (v2).
- **Routage** : `go_router` (navigation par onglets avec `StatefulShellRoute`).
- **Réseau** : `dio` avec intercepteurs pour l'injection du JWT.
- **Stockage local** : `flutter_secure_storage` (token) et `get_storage` (thème).
- **GPS** : `geolocator` pour la lecture des coordonnées.

## Structure Clean Architecture
Dans `lib/features/`, chaque fonctionnalité possède :
- `data/` : Sources de données (Remote, Local) et Implémentations de Repositories.
- `domain/` : Modèles métier (Entités) et Interfaces de Repositories.
- `presentation/` : Screens (UI), Widgets, et Providers (State).

## Fonctionnalités Principales

### 1. Cycle de Demande (Client)
Le client utilise le `FloatingActionButton` pour créer une demande globale (`CreateRequestScreen`). L'application utilise `RequestsRemoteDataSource` pour envoyer uniquement la catégorie et la ville. La requête passe en statut `unassigned`.

### 2. Offres de Mission (Technicien)
L'écran `OffersScreen` poll le provider `offersListProvider` pour récupérer les offres de missions générées par le backend. 
- Les boutons Accepter/Refuser envoient l'action au serveur. 
- En cas de succès (le technicien a gagné la course CAS), il est redirigé vers `requests`.

### 3. Suivi GPS
- **`LocationService`** : Abstraction de `geolocator` qui gère les demandes de permission natives.
- **Partage (Technicien)** : Un bouton sur le détail de la mission envoie la position via `POST /location`.
- **Suivi (Client)** : Un `FutureProvider` récupère la position (`GET /location`) et un bouton `url_launcher` permet de l'ouvrir dans Google Maps.

## Tableaux de Bord
Les écrans d'accueil (`ClientDashboardScreen`, `TechnicianDashboardScreen`) consolident les statistiques des providers métier. La mise à jour est assurée par l'invalidation optimiste des `FutureProvider` ou par le `RefreshIndicator` manuel.
