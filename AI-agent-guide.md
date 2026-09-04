# Guide pour les Agents IA — FixerPro237

Bienvenue, collègue IA. Si vous reprenez ce projet, voici le contexte critique.

## Architecture Majeure
1. **Le Dispatch (Pas un Annuaire)**
   L'application est construite autour d'un algorithme de "Dispatch". Les clients créent une demande (`ServiceRequest`) avec une catégorie et une ville. Le serveur (`DispatchService`) choisit les techniciens éligibles et leur crée des `job_offers`.
   *Règle d'or : Ne modifiez pas la logique d'acceptation sans maîtriser le CAS (Compare-And-Swap) sur l'état de l'offre.*

2. **Relations Strictes**
   - 1 Technicien = 1 Catégorie (`technician_profiles.category_id`). Ne tentez pas de réintroduire des relations many-to-many.
   - Les `location_updates` sont limitées (RLS et Guards API) : Seul le technicien **assigné** peut poster, seul le client/admin peut lire.

## Points d'entrée
- **Backend (Node.js/Express)** : Dossier `backend/`. `src/services/` contient toute la logique métier.
- **Mobile (Flutter)** : Dossier `mobile/`. Architecture Clean (Data, Domain, Presentation). State géré avec Riverpod. Navigation avec GoRouter.

## Ce qui est terminé (MVP V1)
- Authentification & Rôles.
- Cycle de vie complet des requêtes (`unassigned` -> `assigned` -> `inProgress` -> `completed`/`cancelled`).
- GPS en temps réel.
- Notifications et Statistiques (Tableaux de bord).

## Conseils de développement
- Ne modifiez le fichier SQL (`database/schema.sql`) que si vous savez gérer les migrations sur Supabase.
- Avant de proposer un plan de développement, vérifiez `roadmap.md` pour vous assurer de ne pas réimplémenter des fonctionnalités différées (Paiement MoMo, Chat Temps Réel).
