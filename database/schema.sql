-- FixerPro237 Cameroun — Database Schema
-- Supabase-managed PostgreSQL Database Script

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ============================================================================
-- ENUM TYPES
-- ============================================================================

DO $$ BEGIN
    CREATE TYPE user_role AS ENUM ('client', 'technician', 'admin');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
    CREATE TYPE availability_status AS ENUM ('available', 'busy', 'offline');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
    CREATE TYPE request_status AS ENUM ('unassigned', 'dispatched', 'assigned', 'in_progress', 'completed', 'cancelled');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
    CREATE TYPE job_offer_status AS ENUM ('sent', 'accepted', 'declined', 'expired');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
    CREATE TYPE document_type AS ENUM ('id_card', 'certificate');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
    CREATE TYPE document_status AS ENUM ('pending', 'approved', 'rejected');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

-- ============================================================================
-- TABLES
-- ============================================================================

-- 1. Users Table
CREATE TABLE IF NOT EXISTS users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    full_name VARCHAR(150) NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    phone VARCHAR(30),
    password_hash VARCHAR(255) NOT NULL,
    role user_role NOT NULL DEFAULT 'client',
    avatar_url TEXT,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- 2. Regions Table
CREATE TABLE IF NOT EXISTS regions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(100) UNIQUE NOT NULL,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- 3. Cities Table
CREATE TABLE IF NOT EXISTS cities (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(100) NOT NULL,
    region_id UUID NOT NULL REFERENCES regions(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT unique_city_per_region UNIQUE (name, region_id)
);

-- 4. Categories Table
CREATE TABLE IF NOT EXISTS categories (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(100) UNIQUE NOT NULL,
    icon VARCHAR(100),
    description TEXT,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- 5. Technician Profiles Table
CREATE TABLE IF NOT EXISTS technician_profiles (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID UNIQUE NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    category_id UUID REFERENCES categories(id) ON DELETE SET NULL,
    bio TEXT,
    years_experience INT DEFAULT 0 CHECK (years_experience >= 0),
    price_min NUMERIC(10, 2) DEFAULT 0.00 CHECK (price_min >= 0),
    price_max NUMERIC(10, 2) DEFAULT 0.00 CHECK (price_max >= price_min),
    whatsapp VARCHAR(30),
    city_id UUID REFERENCES cities(id) ON DELETE SET NULL,
    verified BOOLEAN DEFAULT FALSE,
    availability availability_status DEFAULT 'available',
    active_job_count INT DEFAULT 0 CHECK (active_job_count >= 0),
    rating_avg NUMERIC(3, 2) DEFAULT 0.00 CHECK (rating_avg >= 0.00 AND rating_avg <= 5.00),
    rating_count INT DEFAULT 0 CHECK (rating_count >= 0),
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- (Table technician_categories removed because 1 technician = 1 category)

-- 7. Technician Verification Documents Table
CREATE TABLE IF NOT EXISTS technician_documents (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    technician_id UUID NOT NULL REFERENCES technician_profiles(id) ON DELETE CASCADE,
    document_type document_type NOT NULL,
    file_url TEXT NOT NULL,
    status document_status DEFAULT 'pending',
    rejection_reason TEXT,
    uploaded_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    reviewed_at TIMESTAMPTZ
);

-- 8. Service Requests Table
CREATE TABLE IF NOT EXISTS service_requests (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    client_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    assigned_technician_id UUID REFERENCES technician_profiles(id) ON DELETE SET NULL,
    category_id UUID NOT NULL REFERENCES categories(id) ON DELETE CASCADE,
    city_id UUID NOT NULL REFERENCES cities(id) ON DELETE CASCADE,
    status request_status DEFAULT 'unassigned',
    description TEXT NOT NULL,
    address TEXT,
    latitude NUMERIC(10, 8),
    longitude NUMERIC(11, 8),
    image_url TEXT,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    completed_at TIMESTAMPTZ
);

-- 8.5. Job Offers Table
CREATE TABLE IF NOT EXISTS job_offers (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    request_id UUID NOT NULL REFERENCES service_requests(id) ON DELETE CASCADE,
    technician_id UUID NOT NULL REFERENCES technician_profiles(id) ON DELETE CASCADE,
    status job_offer_status DEFAULT 'sent',
    rank INT NOT NULL DEFAULT 1,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    responded_at TIMESTAMPTZ,
    CONSTRAINT unique_offer_per_tech_req UNIQUE (request_id, technician_id)
);

-- 8.6. Location Updates Table (Live GPS Tracking)
CREATE TABLE IF NOT EXISTS location_updates (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    request_id UUID NOT NULL REFERENCES service_requests(id) ON DELETE CASCADE,
    technician_id UUID NOT NULL REFERENCES technician_profiles(id) ON DELETE CASCADE,
    latitude NUMERIC(10, 8) NOT NULL,
    longitude NUMERIC(11, 8) NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT unique_location_per_req UNIQUE (request_id)
);

-- 9. Reviews Table (Enforced 1 review per completed request)
CREATE TABLE IF NOT EXISTS reviews (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    request_id UUID UNIQUE NOT NULL REFERENCES service_requests(id) ON DELETE CASCADE,
    client_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    technician_id UUID NOT NULL REFERENCES technician_profiles(id) ON DELETE CASCADE,
    rating INT NOT NULL CHECK (rating >= 1 AND rating <= 5),
    comment TEXT,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- 10. Favorites Table
CREATE TABLE IF NOT EXISTS favorites (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    client_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    technician_id UUID NOT NULL REFERENCES technician_profiles(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT unique_favorite_per_client UNIQUE (client_id, technician_id)
);

-- 11. Notifications Table
CREATE TABLE IF NOT EXISTS notifications (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    type VARCHAR(50) NOT NULL, -- 'request_status_change', 'verification_update', 'system'
    title VARCHAR(200) NOT NULL,
    message TEXT NOT NULL,
    is_read BOOLEAN DEFAULT FALSE,
    metadata JSONB DEFAULT '{}'::jsonb,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- ============================================================================
-- INDEXES
-- ============================================================================

CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);
CREATE INDEX IF NOT EXISTS idx_users_role ON users(role);
CREATE INDEX IF NOT EXISTS idx_cities_region ON cities(region_id);
CREATE INDEX IF NOT EXISTS idx_tech_profiles_city ON technician_profiles(city_id);
CREATE INDEX IF NOT EXISTS idx_tech_profiles_verified ON technician_profiles(verified);
CREATE INDEX IF NOT EXISTS idx_tech_profiles_availability ON technician_profiles(availability);
CREATE INDEX IF NOT EXISTS idx_tech_profiles_rating ON technician_profiles(rating_avg DESC);
CREATE INDEX IF NOT EXISTS idx_requests_client ON service_requests(client_id);
CREATE INDEX IF NOT EXISTS idx_requests_assigned_tech ON service_requests(assigned_technician_id);
CREATE INDEX IF NOT EXISTS idx_requests_status ON service_requests(status);
CREATE INDEX IF NOT EXISTS idx_job_offers_tech_status ON job_offers(technician_id, status);
CREATE INDEX IF NOT EXISTS idx_location_updates_req ON location_updates(request_id);
CREATE INDEX IF NOT EXISTS idx_reviews_technician ON reviews(technician_id);
CREATE INDEX IF NOT EXISTS idx_favorites_client ON favorites(client_id);
CREATE INDEX IF NOT EXISTS idx_notifications_user ON notifications(user_id, is_read);

-- ============================================================================
-- FUNCTIONS AND TRIGGERS
-- ============================================================================

-- Auto-update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER trigger_users_updated_at
    BEFORE UPDATE ON users
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE OR REPLACE TRIGGER trigger_technician_profiles_updated_at
    BEFORE UPDATE ON technician_profiles
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE OR REPLACE TRIGGER trigger_service_requests_updated_at
    BEFORE UPDATE ON service_requests
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Maintain active_job_count for technicians
CREATE OR REPLACE FUNCTION maintain_active_job_count()
RETURNS TRIGGER AS $$
BEGIN
    -- If assigned
    IF (TG_OP = 'UPDATE' AND OLD.assigned_technician_id IS NULL AND NEW.assigned_technician_id IS NOT NULL) THEN
        UPDATE technician_profiles SET active_job_count = active_job_count + 1 WHERE id = NEW.assigned_technician_id;
    END IF;
    -- If completed or cancelled
    IF (TG_OP = 'UPDATE' AND OLD.status IN ('assigned', 'in_progress') AND NEW.status IN ('completed', 'cancelled') AND NEW.assigned_technician_id IS NOT NULL) THEN
        UPDATE technician_profiles SET active_job_count = GREATEST(active_job_count - 1, 0) WHERE id = NEW.assigned_technician_id;
    END IF;
    -- If technician changed (edge case)
    IF (TG_OP = 'UPDATE' AND OLD.assigned_technician_id IS NOT NULL AND NEW.assigned_technician_id IS NOT NULL AND OLD.assigned_technician_id != NEW.assigned_technician_id) THEN
        UPDATE technician_profiles SET active_job_count = GREATEST(active_job_count - 1, 0) WHERE id = OLD.assigned_technician_id;
        UPDATE technician_profiles SET active_job_count = active_job_count + 1 WHERE id = NEW.assigned_technician_id;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER trigger_maintain_active_job_count
    AFTER UPDATE OF assigned_technician_id, status ON service_requests
    FOR EACH ROW EXECUTE FUNCTION maintain_active_job_count();

-- Automatic calculation of rating_avg and rating_count for technicians
CREATE OR REPLACE FUNCTION refresh_technician_rating()
RETURNS TRIGGER AS $$
DECLARE
    target_tech_id UUID;
BEGIN
    IF (TG_OP = 'DELETE') THEN
        target_tech_id := OLD.technician_id;
    ELSE
        target_tech_id := NEW.technician_id;
    END IF;

    UPDATE technician_profiles
    SET 
        rating_avg = COALESCE((
            SELECT ROUND(AVG(rating)::numeric, 2)
            FROM reviews
            WHERE technician_id = target_tech_id
        ), 0.00),
        rating_count = (
            SELECT COUNT(*)
            FROM reviews
            WHERE technician_id = target_tech_id
        )
    WHERE id = target_tech_id;

    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER trigger_refresh_technician_rating
    AFTER INSERT OR UPDATE OR DELETE ON reviews
    FOR EACH ROW EXECUTE FUNCTION refresh_technician_rating();

-- Automatic profile creation for technicians on user creation
CREATE OR REPLACE FUNCTION handle_new_user_registration()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.role = 'technician' THEN
        INSERT INTO technician_profiles (user_id)
        VALUES (NEW.id)
        ON CONFLICT (user_id) DO NOTHING;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER trigger_on_user_created
    AFTER INSERT ON users
    FOR EACH ROW EXECUTE FUNCTION handle_new_user_registration();

-- ============================================================================
-- SEED DATA
-- ============================================================================

-- Seed Regions of Cameroon
INSERT INTO regions (id, name) VALUES
    ('00000000-0000-0000-0000-000000000001', 'Centre'),
    ('00000000-0000-0000-0000-000000000002', 'Littoral'),
    ('00000000-0000-0000-0000-000000000003', 'Ouest'),
    ('00000000-0000-0000-0000-000000000004', 'Nord-Ouest'),
    ('00000000-0000-0000-0000-000000000005', 'Sud-Ouest'),
    ('00000000-0000-0000-0000-000000000006', 'Sud'),
    ('00000000-0000-0000-0000-000000000007', 'Est'),
    ('00000000-0000-0000-0000-000000000008', 'Adamaoua'),
    ('00000000-0000-0000-0000-000000000009', 'Nord'),
    ('00000000-0000-0000-0000-000000000010', 'Extrême-Nord')
ON CONFLICT (name) DO NOTHING;

-- Seed Cities
INSERT INTO cities (id, name, region_id) VALUES
    ('10000000-0000-0000-0000-000000000001', 'Yaoundé', '00000000-0000-0000-0000-000000000001'),
    ('10000000-0000-0000-0000-000000000002', 'Douala', '00000000-0000-0000-0000-000000000002'),
    ('10000000-0000-0000-0000-000000000003', 'Bafoussam', '00000000-0000-0000-0000-000000000003'),
    ('10000000-0000-0000-0000-000000000004', 'Bamenda', '00000000-0000-0000-0000-000000000004'),
    ('10000000-0000-0000-0000-000000000005', 'Buea', '00000000-0000-0000-0000-000000000005'),
    ('10000000-0000-0000-0000-000000000006', 'Kribi', '00000000-0000-0000-0000-000000000006'),
    ('10000000-0000-0000-0000-000000000007', 'Bertoua', '00000000-0000-0000-0000-000000000007'),
    ('10000000-0000-0000-0000-000000000008', 'Ngaoundéré', '00000000-0000-0000-0000-000000000008'),
    ('10000000-0000-0000-0000-000000000009', 'Garoua', '00000000-0000-0000-0000-000000000009'),
    ('10000000-0000-0000-0000-000000000010', 'Maroua', '00000000-0000-0000-0000-000000000010')
ON CONFLICT (name, region_id) DO NOTHING;

-- Seed 21 Service Categories
INSERT INTO categories (id, name, icon, description) VALUES
    ('20000000-0000-0000-0000-000000000001', 'Électricien', 'bolt', 'Dépannage, câblage, installation électrique et groupes électrogènes'),
    ('20000000-0000-0000-0000-000000000002', 'Plombier', 'water_drop', 'Réparation de fuites, débouchage, installation sanitaire et tuyauterie'),
    ('20000000-0000-0000-0000-000000000003', 'Mécanicien', 'build', 'Entretien et réparation automobile, diagnostic moteur et vidange'),
    ('20000000-0000-0000-0000-000000000004', 'Menuisier', 'carpenter', 'Fabrication et réparation de meubles en bois, portes et placards'),
    ('20000000-0000-0000-0000-000000000005', 'Réparateur Téléphone & Informatique', 'phone_android', 'Réparation d''écrans, batteries, logiciels ordinateurs et téléphones'),
    ('20000000-0000-0000-0000-000000000006', 'Tailleur / Styliste', 'checkroom', 'Confection de vêtements sur mesure, retouches et tenues traditionnelles'),
    ('20000000-0000-0000-0000-000000000007', 'Peintre', 'format_paint', 'Peinture d''intérieur et extérieur, traitement des murs et façades'),
    ('20000000-0000-0000-0000-000000000008', 'Maçon', 'engineering', 'Construction, travaux de maçonnerie, fondations et rénovation'),
    ('20000000-0000-0000-0000-000000000009', 'Climatisation & Froid', 'ac_unit', 'Installation et entretien de climatiseurs, réfrigérateurs et chambres froides'),
    ('20000000-0000-0000-0000-000000000010', 'Carreleur', 'grid_on', 'Pose de carrelage, faïence, marbre et dalles d''intérieur/extérieur'),
    ('20000000-0000-0000-0000-000000000011', 'Jardinier', 'grass', 'Entretien d''espaces verts, taille de haies et aménagement paysager'),
    ('20000000-0000-0000-0000-000000000012', 'Coiffeur & Esthétique', 'content_cut', 'Coiffure à domicile, soins esthétiques et tresses'),
    ('20000000-0000-0000-0000-000000000013', 'Serrurier', 'key', 'Ouverture de portes bloquées, changement de serrures et blindage'),
    ('20000000-0000-0000-0000-000000000014', 'Soudeur', 'precision_manufacturing', 'Travaux de soudure métallique, portails, grilles de sécurité'),
    ('20000000-0000-0000-0000-000000000015', 'Cordonnier', 'roller_skating', 'Réparation de chaussures, sacs en cuir et maroquinerie'),
    ('20000000-0000-0000-0000-000000000016', 'Décorateur', 'chair', 'Décoration d''intérieur, évènementielle et aménagement'),
    ('20000000-0000-0000-0000-000000000017', 'Déménageur', 'local_shipping', 'Transport de meubles, emballage et manutention'),
    ('20000000-0000-0000-0000-000000000018', 'Services de Nettoyage', 'cleaning_services', 'Nettoyage de maisons, bureaux, tapis et fin de chantier'),
    ('20000000-0000-0000-0000-000000000019', 'Installateur TV & Canal+', 'tv', 'Installation d''antennes paraboles, décodeurs et câblage TV'),
    ('20000000-0000-0000-0000-000000000020', 'Lavage & Nettoyage Auto', 'local_car_wash', 'Lavage complet de véhicules à domicile et pressing intérieur'),
    ('20000000-0000-0000-0000-000000000021', 'Maintenance Électroménager', 'kitchen', 'Réparation de machines à laver, micro-ondes et gazinières')
ON CONFLICT (name) DO NOTHING;

-- Seed Default Test Accounts (Passwords hashed with bcrypt 10 rounds)
-- Hash for "admin" is "$2a$10$TtTqE0qamOh3UC4OgIUPK.fJVaCPSFxqUMaPmAMbtS1sSXEohvhqm"
INSERT INTO users (id, full_name, email, phone, password_hash, role) VALUES
    ('30000000-0000-0000-0000-000000000001', 'Admin FixerPro237', 'admin@gmail.com', '+237690000000', '$2a$10$TtTqE0qamOh3UC4OgIUPK.fJVaCPSFxqUMaPmAMbtS1sSXEohvhqm', 'admin'),
    ('30000000-0000-0000-0000-000000000002', 'Jean Client', 'client@fixerpro237.cm', '+237691111111', '$2b$10$iWbH0dFjA6wB78E/.1oZse0V71gE.e1Vd3jH.nCj1x/32uO4mZk.S', 'client'),
    ('30000000-0000-0000-0000-000000000003', 'Samuel Électricien', 'samuel@fixerpro237.cm', '+237692222222', '$2b$10$iWbH0dFjA6wB78E/.1oZse0V71gE.e1Vd3jH.nCj1x/32uO4mZk.S', 'technician')
ON CONFLICT (email) DO NOTHING;

-- Seed Technician Profile for Samuel
INSERT INTO technician_profiles (id, user_id, category_id, bio, years_experience, price_min, price_max, whatsapp, city_id, verified, availability, active_job_count) VALUES
    ('40000000-0000-0000-0000-000000000001', '30000000-0000-0000-0000-000000000003', '20000000-0000-0000-0000-000000000001', 'Électricien qualifié avec 8 ans d''expérience à Yaoundé. Spécialiste dépannage rapide et câblage moderne.', 8, 5000.00, 25000.00, '+237692222222', '10000000-0000-0000-0000-000000000001', TRUE, 'available', 0)
ON CONFLICT (user_id) DO UPDATE SET
    id = EXCLUDED.id,
    category_id = EXCLUDED.category_id,
    bio = EXCLUDED.bio,
    years_experience = EXCLUDED.years_experience,
    price_min = EXCLUDED.price_min,
    price_max = EXCLUDED.price_max,
    whatsapp = EXCLUDED.whatsapp,
    city_id = EXCLUDED.city_id,
    verified = EXCLUDED.verified,
    availability = EXCLUDED.availability,
    active_job_count = EXCLUDED.active_job_count;

-- (Samuel is now linked directly in technician_profiles)


-- ==========================================
-- Reports (Manage Reported Users)
-- ==========================================
CREATE TABLE public.reports (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    client_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    technician_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    reason TEXT NOT NULL,
    details TEXT,
    status TEXT NOT NULL DEFAULT 'pending', -- 'pending', 'resolved'
    action_taken TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    resolved_at TIMESTAMP WITH TIME ZONE
);

-- Enable Row Level Security (RLS)
ALTER TABLE public.reports ENABLE ROW LEVEL SECURITY;

-- Policy: Clients can create reports
CREATE POLICY "Clients can create reports"
ON public.reports
FOR INSERT
WITH CHECK (auth.uid() = client_id);

-- Policy: Admins can view and update all reports
CREATE POLICY "Admins can view all reports"
ON public.reports
FOR SELECT
USING (
  EXISTS (
    SELECT 1 FROM public.users
    WHERE users.id = auth.uid() AND users.role = 'admin'
  )
);

CREATE POLICY "Admins can update reports"
ON public.reports
FOR UPDATE
USING (
  EXISTS (
    SELECT 1 FROM public.users
    WHERE users.id = auth.uid() AND users.role = 'admin'
  )
);

-- ==========================================
-- Location Updates RLS (GPS Tracking)
-- ==========================================

ALTER TABLE public.location_updates ENABLE ROW LEVEL SECURITY;

-- Policy: Technicians can insert/update their own location for active assigned requests
CREATE POLICY "Technicians can manage location for their assigned requests"
ON public.location_updates
FOR ALL
USING (
  EXISTS (
    SELECT 1 FROM public.technician_profiles tp
    WHERE tp.id = technician_id AND tp.user_id = auth.uid()
  )
);

-- Policy: Clients can view location of their own requests
CREATE POLICY "Clients can view location of their requests"
ON public.location_updates
FOR SELECT
USING (
  EXISTS (
    SELECT 1 FROM public.service_requests sr
    WHERE sr.id = request_id AND sr.client_id = auth.uid()
  )
);
