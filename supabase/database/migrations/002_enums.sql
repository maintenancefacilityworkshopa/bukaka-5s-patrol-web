-- ============================================================================
-- 002_enums.sql
-- Keterangan: Tipe Data Enum untuk Role, Status Temuan, dan Kategori 5S
-- ============================================================================

-- 1. Enum Role Pengguna
-- Ganti definisi app_role sebelumnya menjadi:
CREATE TYPE app_role AS ENUM (
  'ADMIN',
  'STAFF_AHLI',
  'STAFF_INTERNSHIP'
);

-- 2. Enum Status Temuan Patroli (Flow Lifecycle 5S)
CREATE TYPE public.patrol_status AS ENUM (
    'OPEN',         -- Temuan dibuat oleh Inspector
    'IN_PROGRESS',  -- Dalam proses pengerjaan perbaikan
    'CLOSED'        -- Kasus ditutup resmi
);

-- 3. Enum Kategori 5S (Ringkas, Rapi, Resik, Rawat, Rajin)
CREATE TYPE public.category_5s AS ENUM (
    'SEIRI',    -- Ringkas (Sort)
    'SEITON',   -- Rapi (Set in Order)
    'SEISO',    -- Resik (Shine)
    'SEIKETSU', -- Rawat (Standardize)
    'SHITSUKE'  -- Rajin (Sustain)
);

-- 4. Enum Tingkat Keparahan / Priority
CREATE TYPE public.finding_severity AS ENUM (
    'LOW',
    'MEDIUM',
    'HIGH',
    'CRITICAL'
);