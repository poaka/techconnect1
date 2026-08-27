# Documentation Backend - FixerPro237

Le backend Node.js/Express de FixerPro237 est le moteur intelligent de la plateforme.

## Architecture

- **Routes (`src/routes/`)** : Définissent les points d'entrée de l'API. Chaque route est protégée par des middlewares d'authentification (`requireAuth`) et de rôles.
- **Controllers (`src/controllers/`)** : Orchestrent la logique entre les requêtes HTTP et les services métier.
- **Services (`src/services/`)** : Contiennent la logique métier (SQL avec Supabase). C'est là que le lourd travail est effectué.

## Modules Clés

### 1. DispatchService (`src/services/dispatch.service.js`)
L'algorithme de dispatch est responsable de trouver les techniciens appropriés pour une nouvelle demande.
- Il filtre par : Ville, Catégorie, Statut de vérification, Disponibilité.
- Il trie par : Le technicien ayant le moins de requêtes actives (`active_job_count` ASC), avec un tie-breaker déterministe (rating_avg ou date de création).

### 2. OffersService (`src/services/offers.service.js`)
Gère l'assignation concurrente avec un modèle Compare-And-Swap (CAS).
- `acceptOffer` : Tente de mettre à jour le `assigned_technician_id` de la requête UNIQUEMENT s'il est actuellement NULL. Cela garantit qu'un seul technicien gagne l'offre, même si 10 essaient d'accepter à la milliseconde près.
- Invalide (`expired`) automatiquement les autres offres en attente pour cette même demande.

### 3. RequestsService (`src/services/requests.service.js`)
Gère le cycle de vie (`unassigned`, `assigned`, `in_progress`, `completed`, `cancelled`) et inclut le sous-système de localisation GPS (`updateLocation`, `getLocation`).

## Base de Données
Le backend dialogue avec Supabase en utilisant `supabase-js`. L'intégrité des données (comme `active_job_count`) est maintenue par des **Triggers PostgreSQL** directement dans la base (`schema.sql`), et non dans le code Node.js.
