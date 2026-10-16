-- 005_schedule_table.sql
-- Schedule follows the Bukaka template: 1 period contains week 1-4;
-- each week has locations and 1..N patrol members.

CREATE TABLE public.schedule_periods (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    title VARCHAR(255) NOT NULL,
    description TEXT,
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    status public.schedule_status NOT NULL DEFAULT 'DRAFT',
    source_file_name TEXT,
    created_by UUID NOT NULL REFERENCES public.profiles(id) ON DELETE RESTRICT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT chk_schedule_period_dates CHECK (end_date >= start_date)
);

CREATE TABLE public.schedule_weeks (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    schedule_id UUID NOT NULL REFERENCES public.schedule_periods(id) ON DELETE CASCADE,
    week_number SMALLINT NOT NULL,
    patrol_date DATE NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT chk_schedule_week_number CHECK (week_number BETWEEN 1 AND 4),
    CONSTRAINT uq_schedule_week UNIQUE (schedule_id, week_number)
);

CREATE TABLE public.schedule_assignments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    schedule_week_id UUID NOT NULL REFERENCES public.schedule_weeks(id) ON DELETE CASCADE,
    location_id UUID NOT NULL REFERENCES public.locations(id) ON DELETE RESTRICT,
    status public.schedule_assignment_status NOT NULL DEFAULT 'SCHEDULED',
    notes TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT uq_schedule_location UNIQUE (schedule_week_id, location_id)
);

CREATE TABLE public.schedule_members (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    assignment_id UUID NOT NULL REFERENCES public.schedule_assignments(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE RESTRICT,
    sequence_no SMALLINT NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT chk_member_sequence CHECK (sequence_no > 0),
    CONSTRAINT uq_assignment_member UNIQUE (assignment_id, user_id),
    CONSTRAINT uq_assignment_sequence UNIQUE (assignment_id, sequence_no)
);

CREATE TABLE public.schedule_imports (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    schedule_id UUID REFERENCES public.schedule_periods(id) ON DELETE SET NULL,
    file_name TEXT NOT NULL,
    uploaded_by UUID NOT NULL REFERENCES public.profiles(id) ON DELETE RESTRICT,
    status public.import_status NOT NULL DEFAULT 'PROCESSING',
    total_rows INTEGER NOT NULL DEFAULT 0,
    success_rows INTEGER NOT NULL DEFAULT 0,
    failed_rows INTEGER NOT NULL DEFAULT 0,
    errors JSONB,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    completed_at TIMESTAMPTZ
);

CREATE INDEX idx_schedule_periods_status ON public.schedule_periods(status);
CREATE INDEX idx_schedule_weeks_schedule ON public.schedule_weeks(schedule_id);
CREATE INDEX idx_schedule_weeks_date ON public.schedule_weeks(patrol_date);
CREATE INDEX idx_schedule_assignments_week ON public.schedule_assignments(schedule_week_id);
CREATE INDEX idx_schedule_assignments_location ON public.schedule_assignments(location_id);
CREATE INDEX idx_schedule_members_user ON public.schedule_members(user_id);
CREATE INDEX idx_schedule_imports_schedule ON public.schedule_imports(schedule_id);
