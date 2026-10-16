-- 007_patrol_result_tables.sql

CREATE TABLE public.inspection_results (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    inspection_id UUID NOT NULL REFERENCES public.inspection_runs(id) ON DELETE CASCADE,
    checklist_item_id UUID NOT NULL REFERENCES public.checklist_items(id) ON DELETE RESTRICT,
    score SMALLINT NOT NULL CHECK (score BETWEEN 0 AND 4),
    notes TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT uq_inspection_checklist_item UNIQUE (inspection_id, checklist_item_id)
);

CREATE TABLE public.patrol_findings (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    inspection_id UUID REFERENCES public.inspection_runs(id) ON DELETE SET NULL,
    location_id UUID NOT NULL REFERENCES public.locations(id) ON DELETE RESTRICT,
    reported_by UUID NOT NULL REFERENCES public.profiles(id) ON DELETE RESTRICT,
    checklist_item_id UUID REFERENCES public.checklist_items(id) ON DELETE SET NULL,
    description TEXT NOT NULL,
    image_before_url TEXT NOT NULL,
    target_date DATE NOT NULL,
    severity public.finding_severity NOT NULL DEFAULT 'MEDIUM',
    status public.patrol_status NOT NULL DEFAULT 'OPEN',
    handled_by UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
    handled_at TIMESTAMPTZ,
    resolution_notes TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT chk_target_date CHECK (target_date >= created_at::date)
);

CREATE TABLE public.patrol_finding_actions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    finding_id UUID NOT NULL REFERENCES public.patrol_findings(id) ON DELETE CASCADE,
    action_by UUID NOT NULL REFERENCES public.profiles(id) ON DELETE RESTRICT,
    action_taken TEXT NOT NULL,
    image_after_url TEXT NOT NULL,
    action_date TIMESTAMPTZ NOT NULL DEFAULT now(),
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_inspection_results_inspection ON public.inspection_results(inspection_id);
CREATE INDEX idx_inspection_results_item ON public.inspection_results(checklist_item_id);
CREATE INDEX idx_findings_inspection ON public.patrol_findings(inspection_id);
CREATE INDEX idx_findings_reported_by ON public.patrol_findings(reported_by);
CREATE INDEX idx_findings_status ON public.patrol_findings(status);
CREATE INDEX idx_findings_target_date ON public.patrol_findings(target_date);
CREATE INDEX idx_actions_finding ON public.patrol_finding_actions(finding_id);
