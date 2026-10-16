-- ============================================================================
-- FILE: 016_update_roles_and_sync_trigger.sql
-- KETERANGAN: Penyesuaian Role Baru (STAFF_AHLI, STAFF_INTERNSHIP) & Sync Metadata
-- ============================================================================

-- 1. Penambahan Enum Role Baru
DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_type t 
        JOIN pg_enum e ON t.oid = e.enumtypid 
        WHERE t.typname = 'app_role' AND e.enumlabel = 'STAFF_AHLI'
    ) THEN
        ALTER TYPE app_role ADD VALUE 'STAFF_AHLI';
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_type t 
        JOIN pg_enum e ON t.oid = e.enumtypid 
        WHERE t.typname = 'app_role' AND e.enumlabel = 'STAFF_INTERNSHIP'
    ) THEN
        ALTER TYPE app_role ADD VALUE 'STAFF_INTERNSHIP';
    END IF;
END $$;

-- 2. Mengubah Default Constraint pada Tabel Profiles
ALTER TABLE public.profiles 
ALTER COLUMN role SET DEFAULT 'STAFF_AHLI'::app_role;

-- 3. Memperbarui Data Role Existing (Kecuali Admin)
UPDATE public.profiles
SET role = 'STAFF_AHLI'::app_role
WHERE role != 'ADMIN' OR role IS NULL;

-- 4. Membuat Function Sinkronisasi ke Auth Metadata
CREATE OR REPLACE FUNCTION sync_profile_to_auth_user()
RETURNS TRIGGER AS $$
BEGIN
  UPDATE auth.users
  SET raw_user_meta_data = 
    COALESCE(raw_user_meta_data, '{}'::jsonb) || 
    jsonb_build_object(
      'full_name', NEW.full_name,
      'role', NEW.role::text
    )
  WHERE id = NEW.id;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 5. Memasang Trigger Otomatis
DROP TRIGGER IF EXISTS on_profile_update_sync_auth ON public.profiles;

CREATE TRIGGER on_profile_update_sync_auth
AFTER INSERT OR UPDATE OF full_name, role ON public.profiles
FOR EACH ROW
EXECUTE FUNCTION sync_profile_to_auth_user();

-- 6. Sinkronisasi Awal Seluruh User ke Auth Metadata
UPDATE auth.users
SET raw_user_meta_data = 
  COALESCE(raw_user_meta_data, '{}'::jsonb) || 
  jsonb_build_object(
    'full_name', p.full_name,
    'role', p.role::text
  )
FROM public.profiles p
WHERE auth.users.id = p.id;