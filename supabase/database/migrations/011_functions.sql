-- 011_functions.sql

CREATE OR REPLACE FUNCTION public.fn_calculate_inspection_score(p_inspection_id UUID)
RETURNS TABLE (
    total_score NUMERIC,
    max_score NUMERIC,
    score_percentage NUMERIC,
    passed BOOLEAN
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_total NUMERIC(8,2) := 0;
    v_max NUMERIC(8,2) := 0;
    v_percentage NUMERIC(8,2) := 0;
    v_passed BOOLEAN := false;
    v_required_count INTEGER := 0;
    v_answered_count INTEGER := 0;
BEGIN
    SELECT
        COALESCE(SUM(ci.max_score), 0),
        COUNT(*)
    INTO v_max, v_required_count
    FROM public.inspection_runs ir
    JOIN public.checklist_items ci
      ON ci.template_id = ir.checklist_template_id
     AND ci.is_required = true
    WHERE ir.id = p_inspection_id;

    SELECT
        COALESCE(SUM(ir.score), 0),
        COUNT(*)
    INTO v_total, v_answered_count
    FROM public.inspection_results ir
    WHERE ir.inspection_id = p_inspection_id;

    -- A checklist is scored only when all required items have been answered.
    IF v_required_count > 0 AND v_answered_count = v_required_count AND v_max > 0 THEN
        v_percentage := ROUND((v_total / v_max) * 100, 2);
        v_passed := v_percentage >= 70;
    ELSE
        v_percentage := 0;
        v_passed := false;
    END IF;

    UPDATE public.inspection_runs
    SET total_score = v_total,
        max_score = v_max,
        score_percentage = v_percentage,
        passed = v_passed,
        updated_at = now()
    WHERE id = p_inspection_id;

    RETURN QUERY SELECT v_total, v_max, v_percentage, v_passed;
END;
$$;

CREATE OR REPLACE FUNCTION public.fn_get_user_dashboard_stats(p_user_id UUID)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    RETURN json_build_object(
        'open_findings', (
            SELECT COUNT(*) FROM public.patrol_findings
            WHERE reported_by = p_user_id AND status = 'OPEN'
        ),
        'in_progress_findings', (
            SELECT COUNT(*) FROM public.patrol_findings
            WHERE reported_by = p_user_id AND status = 'IN_PROGRESS'
        ),
        'closed_findings', (
            SELECT COUNT(*) FROM public.patrol_findings
            WHERE reported_by = p_user_id AND status = 'CLOSED'
        ),
        'completed_inspections', (
            SELECT COUNT(*) FROM public.inspection_runs
            WHERE created_by = p_user_id AND status = 'SUBMITTED'
        )
    );
END;
$$;

CREATE OR REPLACE FUNCTION public.fn_create_notification(
    p_user_id UUID,
    p_title TEXT,
    p_message TEXT,
    p_type TEXT,
    p_reference_id UUID DEFAULT NULL
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_id UUID;
BEGIN
    INSERT INTO public.notifications(user_id, title, message, type, reference_id)
    VALUES (p_user_id, p_title, p_message, p_type, p_reference_id)
    RETURNING id INTO v_id;
    RETURN v_id;
END;
$$;
