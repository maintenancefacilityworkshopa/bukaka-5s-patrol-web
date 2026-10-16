-- ============================================================================
-- 001_extensions.sql
-- Keterangan: Pembersihan awal dan inisialisasi extension yang dibutuhkan
-- ============================================================================

-- Enable Extension UUID untuk auto-generate ID unik
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Extension pgcrypto jika membutuhkan fungsi hashing/crypto tambahan
CREATE EXTENSION IF NOT EXISTS "pgcrypto";