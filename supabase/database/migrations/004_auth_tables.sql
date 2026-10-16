-- 004_auth_tables.sql
-- Profile identity is linked directly to Supabase Auth.

CREATE TABLE public.profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    nik VARCHAR(50) UNIQUE,
    full_name VARCHAR(150) NOT NULL,
    email VARCHAR(150) UNIQUE,
    role public.app_role NOT NULL DEFAULT 'STAFF_INTERNSHIP',
    department_id UUID REFERENCES public.departments(id) ON DELETE SET NULL,
    avatar_url TEXT,
    phone VARCHAR(30),
    is_active BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_profiles_role ON public.profiles(role);
CREATE INDEX idx_profiles_department ON public.profiles(department_id);
CREATE INDEX idx_profiles_active ON public.profiles(is_active);

-- Helper used by RLS and application queries.
CREATE OR REPLACE FUNCTION public.fn_get_my_role()
RETURNS public.app_role
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
    SELECT role FROM public.profiles WHERE id = auth.uid() AND is_active = true;
$$;

GRANT EXECUTE ON FUNCTION public.fn_get_my_role() TO authenticated;

-- Automatically create a basic profile when a Supabase Auth user is created.
-- Admin can later complete NIK, department and role from the application.
CREATE OR REPLACE FUNCTION public.fn_handle_new_auth_user()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    INSERT INTO public.profiles (id, email, full_name, role)
    VALUES (
        NEW.id,
        NEW.email,
        COALESCE(NULLIF(NEW.raw_user_meta_data ->> 'full_name', ''), split_part(COALESCE(NEW.email, ''), '@', 1)),
        'STAFF_INTERNSHIP'
    )
    ON CONFLICT (id) DO NOTHING;
    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_on_auth_user_created ON auth.users;
CREATE TRIGGER trg_on_auth_user_created
AFTER INSERT ON auth.users
FOR EACH ROW EXECUTE FUNCTION public.fn_handle_new_auth_user();
