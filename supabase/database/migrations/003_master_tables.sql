-- 003_master_tables.sql

CREATE TABLE public.companies (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    code VARCHAR(20) NOT NULL UNIQUE,
    name VARCHAR(200) NOT NULL,
    address TEXT,
    phone VARCHAR(30),
    email VARCHAR(100),
    logo_url TEXT,
    is_active BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE public.departments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id UUID REFERENCES public.companies(id) ON DELETE SET NULL,
    code VARCHAR(20) NOT NULL UNIQUE,
    name VARCHAR(150) NOT NULL,
    description TEXT,
    display_order INTEGER NOT NULL DEFAULT 1,
    is_active BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE public.locations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    code VARCHAR(30) NOT NULL UNIQUE,
    name VARCHAR(150) NOT NULL,
    location_type public.location_type NOT NULL,
    description TEXT,
    building VARCHAR(100),
    floor VARCHAR(50),
    department_id UUID REFERENCES public.departments(id) ON DELETE SET NULL,
    default_inspector_count INTEGER NOT NULL DEFAULT 2,
    display_order INTEGER NOT NULL DEFAULT 1,
    is_active BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT chk_location_inspector_count CHECK (default_inspector_count > 0)
);

CREATE TABLE public.checklist_categories (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    code VARCHAR(30) NOT NULL UNIQUE,
    name VARCHAR(100) NOT NULL,
    description TEXT,
    display_order INTEGER NOT NULL UNIQUE,
    is_active BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE public.checklist_templates (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    code VARCHAR(50) NOT NULL UNIQUE,
    name VARCHAR(150) NOT NULL,
    location_type public.location_type NOT NULL,
    form_number VARCHAR(50),
    description TEXT,
    version INTEGER NOT NULL DEFAULT 1,
    effective_date DATE,
    expired_date DATE,
    is_active BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT chk_template_dates CHECK (expired_date IS NULL OR effective_date IS NULL OR expired_date >= effective_date)
);

CREATE TABLE public.checklist_items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    template_id UUID NOT NULL REFERENCES public.checklist_templates(id) ON DELETE CASCADE,
    category_id UUID NOT NULL REFERENCES public.checklist_categories(id) ON DELETE RESTRICT,
    item_number INTEGER NOT NULL,
    title TEXT NOT NULL,
    criteria TEXT NOT NULL,
    max_score INTEGER NOT NULL DEFAULT 4,
    is_required BOOLEAN NOT NULL DEFAULT true,
    display_order INTEGER NOT NULL,
    is_active BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT chk_item_score CHECK (max_score = 4),
    CONSTRAINT uq_template_item_number UNIQUE (template_id, item_number)
);

CREATE TABLE public.app_settings (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    setting_key VARCHAR(100) NOT NULL UNIQUE,
    setting_value TEXT,
    description TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_departments_company ON public.departments(company_id);
CREATE INDEX idx_locations_department ON public.locations(department_id);
CREATE INDEX idx_locations_type ON public.locations(location_type);
CREATE INDEX idx_checklist_items_template ON public.checklist_items(template_id);
CREATE INDEX idx_checklist_items_category ON public.checklist_items(category_id);
