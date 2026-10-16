-- 010_views.sql

CREATE OR REPLACE VIEW public.v_schedule_matrix AS
SELECT
    sp.id AS schedule_id,
    sp.title,
    sp.start_date,
    sp.end_date,
    sp.status AS schedule_status,
    sw.id AS week_id,
    sw.week_number,
    sw.patrol_date,
    sa.id AS assignment_id,
    l.id AS location_id,
    l.code AS location_code,
    l.name AS location_name,
    l.location_type,
    sa.status AS assignment_status,
    sm.sequence_no,
    p.id AS user_id,
    p.full_name AS user_name,
    p.role AS user_role
FROM public.schedule_periods sp
JOIN public.schedule_weeks sw ON sw.schedule_id = sp.id
JOIN public.schedule_assignments sa ON sa.schedule_week_id = sw.id
JOIN public.locations l ON l.id = sa.location_id
JOIN public.schedule_members sm ON sm.assignment_id = sa.id
JOIN public.profiles p ON p.id = sm.user_id;

CREATE OR REPLACE VIEW public.v_inspection_summary AS
SELECT
    ir.id AS inspection_id,
    ir.inspected_at,
    ir.status,
    ir.location_id,
    l.code AS location_code,
    l.name AS location_name,
    l.location_type,
    ct.code AS checklist_code,
    ct.name AS checklist_name,
    ir.total_score,
    ir.max_score,
    ir.score_percentage,
    ir.passing_grade,
    ir.passed,
    p.full_name AS created_by_name
FROM public.inspection_runs ir
JOIN public.locations l ON l.id = ir.location_id
JOIN public.checklist_templates ct ON ct.id = ir.checklist_template_id
JOIN public.profiles p ON p.id = ir.created_by;

CREATE OR REPLACE VIEW public.v_patrol_findings_summary AS
SELECT
    pf.id AS finding_id,
    pf.inspection_id,
    pf.description,
    pf.image_before_url,
    pf.target_date,
    pf.severity,
    pf.status,
    pf.reported_by,
    reporter.full_name AS reported_by_name,
    pf.handled_by,
    handler.full_name AS handled_by_name,
    pf.handled_at,
    pf.resolution_notes,
    pfa.id AS action_id,
    pfa.action_taken,
    pfa.image_after_url,
    pfa.action_date,
    l.id AS location_id,
    l.name AS location_name,
    l.location_type,
    pf.created_at,
    pf.updated_at
FROM public.patrol_findings pf
JOIN public.locations l ON l.id = pf.location_id
JOIN public.profiles reporter ON reporter.id = pf.reported_by
LEFT JOIN public.profiles handler ON handler.id = pf.handled_by
LEFT JOIN LATERAL (
    SELECT a.*
    FROM public.patrol_finding_actions a
    WHERE a.finding_id = pf.id
    ORDER BY a.created_at DESC
    LIMIT 1
) pfa ON true;

CREATE OR REPLACE VIEW public.v_dashboard_stats AS
SELECT
    (SELECT COUNT(*) FROM public.patrol_findings WHERE status = 'OPEN') AS open_findings,
    (SELECT COUNT(*) FROM public.patrol_findings WHERE status = 'IN_PROGRESS') AS in_progress_findings,
    (SELECT COUNT(*) FROM public.patrol_findings WHERE status = 'CLOSED') AS closed_findings,
    (SELECT COUNT(*) FROM public.profiles WHERE is_active = true) AS active_users,
    (SELECT COUNT(*) FROM public.schedule_assignments sa
       JOIN public.schedule_weeks sw ON sw.id = sa.schedule_week_id
       WHERE sw.patrol_date = CURRENT_DATE
         AND sa.status = 'SCHEDULED') AS today_schedules;
