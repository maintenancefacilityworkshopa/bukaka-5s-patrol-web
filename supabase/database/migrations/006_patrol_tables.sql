-- 006_patrol_tables.sql
-- Inspection/checklist execution is separated from patrol findings.

CREATE TABLE public.inspection_runs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    schedule_assignment_id UUID REFERENCES public.schedule_assignments(id) ON DELETE SET NULL,
    location_id UUID NOT NULL REFERENCES public.locations(id) ON DELETE RESTRICT,
    checklist_template_id UUID NOT NULL REFERENCES public.checklist_templates(id) ON DELETE RESTRICT,
    inspected_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    created_by UUID NOT NULL REFERENCES public.profiles(id) ON DELETE RESTRICT,
    status public.inspection_status NOT NULL DEFAULT 'DRAFT',
    total_score NUMERIC(6,2) NOT NULL DEFAULT 0,
    max_score NUMERIC(6,2) NOT NULL DEFAULT 0,
    score_percentage NUMERIC(6,2) NOT NULL DEFAULT 0,
    passing_grade NUMERIC(6,2) NOT NULL DEFAULT 70,
    passed BOOLEAN NOT NULL DEFAULT false,
    notes TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT chk_inspection_scores CHECK (total_score >= 0 AND max_score >= 0 AND score_percentage >= 0),
    CONSTRAINT chk_inspection_passing_grade CHECK (passing_grade >= 0 AND passing_grade <= 100)
);

CREATE TABLE public.inspection_inspectors (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    inspection_id UUID NOT NULL REFERENCES public.inspection_runs(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE RESTRICT,
    sequence_no SMALLINT NOT NULL DEFAULT 1,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT chk_inspection_inspector_sequence CHECK (sequence_no > 0),
    CONSTRAINT uq_inspection_inspector UNIQUE (inspection_id, user_id),
    CONSTRAINT uq_inspection_inspector_sequence UNIQUE (inspection_id, sequence_no)
);

CREATE INDEX idx_inspection_runs_assignment ON public.inspection_runs(schedule_assignment_id);
CREATE INDEX idx_inspection_runs_location ON public.inspection_runs(location_id);
CREATE INDEX idx_inspection_runs_created_by ON public.inspection_runs(created_by);
CREATE INDEX idx_inspection_runs_status ON public.inspection_runs(status);
CREATE INDEX idx_inspection_inspectors_user ON public.inspection_inspectors(user_id);
