# FixerPro237 Cameroun — Roadmap & Status

L'application FixerPro237 a pivoté de son modèle initial "Annuaire Ouvert" vers un modèle "Dispatch Intelligent" (assignation automatique, 1 seule catégorie par technicien).
Ce document reflète l'implémentation finale de la V1.

## Phase 0 — Décisions Tranchées
**Status: ✅ TERMINÉ**
- Modèle de Dispatch retenu : Le client demande, le système choisit, le technicien accepte/refuse.
- 1 seule catégorie par technicien pour simplifier la facturation.
- Focus sur Flutter (Mobile) et suppression du React Web (Admin gardé basique via requêtes API ou interface minimale).

## Phase 1 — Refonte du Schéma DB
**Status: ✅ TERMINÉ**
- Retrait de `technician_categories` au profit de `technician_profiles.category_id`.
- Création de la table `job_offers` (id, request_id, technician_id, status, expires_at).
- Création de la table `location_updates`.
- `service_requests` utilise `assigned_technician_id` (nullable) et `city_id`.

## Phase 2 — Moteur de Dispatch (Backend)
**Status: ✅ TERMINÉ**
- `DispatchService` trouve les techniciens pertinents (même ville, même catégorie, vérifiés, disponibles, avec le moins de requêtes actives).
- Algorithme déterministe pour éviter les blocages.

## Phase 3 — Assignation Atomique (Backend)
**Status: ✅ TERMINÉ**
- Service d'offres (`OffersService`) avec Compare-And-Swap (CAS) pour s'assurer que si plusieurs techniciens tentent d'accepter une offre simultanément, un seul gagne.
- Invalidation des autres offres une fois qu'une est acceptée.

## Phase 4 — API Offres et Lifecycle (Backend)
**Status: ✅ TERMINÉ**
- Endpoints `GET /technician/offers`, `POST /offers/:id/accept`, `POST /offers/:id/reject`.
- `POST /requests/:id/cancel` (Client).
- `POST /requests/:id/complete` (Technicien).

## Phase 5 — API GPS (Backend)
**Status: ✅ TERMINÉ**
- `POST /requests/:id/location` : Le technicien assigné envoie sa position.
- `GET /requests/:id/location` : Le client et l'admin peuvent voir la position.
- RLS / Guards de sécurité vérifiés.

## Phase 6 — Client : Création de demande (Mobile)
**Status: ✅ TERMINÉ**
- Remplacement du vieux formulaire.
- Saisie globale avec liste déroulante (Catégorie, Ville).
- État de la requête : `unassigned` (affiché comme "Recherche en cours...").

## Phase 7 — Technicien : Offres de Mission (Mobile)
**Status: ✅ TERMINÉ**
- Nouvel écran `OffersScreen` affichant les demandes entrantes.
- Compte à rebours avant expiration.
- Boutons "Accepter" (vert) et "Refuser" (rouge).

## Phase 8 — GPS & Tracking (Mobile)
**Status: ✅ TERMINÉ**
- Intégration de `geolocator`.
- Côté Technicien : Bouton pour partager la position GPS lors d'une mission en cours.
- Côté Client : Vue de suivi avec horodatage et bouton "Ouvrir dans Maps".

## Phase 9 — Documentation Finale
**Status: ✅ TERMINÉ**
- Tous les documents (`roadmap.md`, `FEATURE_GAP_ANALYSIS.md`, `BACKEND_DOCS.md`, `MOBILE_DOCS.md`) sont alignés avec le code.

---

**Toutes les étapes du plan de vérification (`plan-verifier.md`) sont validées. Le MVP V1 est prêt pour déploiement.**
