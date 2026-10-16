-- 012_triggers.sql

CREATE OR REPLACE FUNCTION public.fn_set_updated_at()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$;

CREATE OR REPLACE TRIGGER trg_companies_updated_at BEFORE UPDATE ON public.companies FOR EACH ROW EXECUTE FUNCTION public.fn_set_updated_at();
CREATE OR REPLACE TRIGGER trg_departments_updated_at BEFORE UPDATE ON public.departments FOR EACH ROW EXECUTE FUNCTION public.fn_set_updated_at();
CREATE OR REPLACE TRIGGER trg_locations_updated_at BEFORE UPDATE ON public.locations FOR EACH ROW EXECUTE FUNCTION public.fn_set_updated_at();
CREATE OR REPLACE TRIGGER trg_categories_updated_at BEFORE UPDATE ON public.checklist_categories FOR EACH ROW EXECUTE FUNCTION public.fn_set_updated_at();
CREATE OR REPLACE TRIGGER trg_templates_updated_at BEFORE UPDATE ON public.checklist_templates FOR EACH ROW EXECUTE FUNCTION public.fn_set_updated_at();
CREATE OR REPLACE TRIGGER trg_items_updated_at BEFORE UPDATE ON public.checklist_items FOR EACH ROW EXECUTE FUNCTION public.fn_set_updated_at();
CREATE OR REPLACE TRIGGER trg_settings_updated_at BEFORE UPDATE ON public.app_settings FOR EACH ROW EXECUTE FUNCTION public.fn_set_updated_at();
CREATE OR REPLACE TRIGGER trg_profiles_updated_at BEFORE UPDATE ON public.profiles FOR EACH ROW EXECUTE FUNCTION public.fn_set_updated_at();
CREATE OR REPLACE TRIGGER trg_schedule_periods_updated_at BEFORE UPDATE ON public.schedule_periods FOR EACH ROW EXECUTE FUNCTION public.fn_set_updated_at();
CREATE OR REPLACE TRIGGER trg_schedule_weeks_updated_at BEFORE UPDATE ON public.schedule_weeks FOR EACH ROW EXECUTE FUNCTION public.fn_set_updated_at();
CREATE OR REPLACE TRIGGER trg_schedule_assignments_updated_at BEFORE UPDATE ON public.schedule_assignments FOR EACH ROW EXECUTE FUNCTION public.fn_set_updated_at();
CREATE OR REPLACE TRIGGER trg_inspection_runs_updated_at BEFORE UPDATE ON public.inspection_runs FOR EACH ROW EXECUTE FUNCTION public.fn_set_updated_at();
CREATE OR REPLACE TRIGGER trg_inspection_results_updated_at BEFORE UPDATE ON public.inspection_results FOR EACH ROW EXECUTE FUNCTION public.fn_set_updated_at();
CREATE OR REPLACE TRIGGER trg_patrol_findings_updated_at BEFORE UPDATE ON public.patrol_findings FOR EACH ROW EXECUTE FUNCTION public.fn_set_updated_at();
CREATE OR REPLACE TRIGGER trg_patrol_actions_updated_at BEFORE UPDATE ON public.patrol_finding_actions FOR EACH ROW EXECUTE FUNCTION public.fn_set_updated_at();

CREATE OR REPLACE FUNCTION public.fn_recalculate_inspection_score()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    PERFORM public.fn_calculate_inspection_score(
        CASE WHEN TG_OP = 'DELETE' THEN OLD.inspection_id ELSE NEW.inspection_id END
    );
    RETURN NULL;
END;
$$;

CREATE OR REPLACE TRIGGER trg_recalculate_inspection_score
AFTER INSERT OR UPDATE OR DELETE ON public.inspection_results
FOR EACH ROW EXECUTE FUNCTION public.fn_recalculate_inspection_score();

-- New finding -> notify every active admin.
CREATE OR REPLACE FUNCTION public.fn_notify_admin_new_finding()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_location TEXT;
    v_reporter TEXT;
    v_admin RECORD;
BEGIN
    SELECT name INTO v_location FROM public.locations WHERE id = NEW.location_id;
    SELECT full_name INTO v_reporter FROM public.profiles WHERE id = NEW.reported_by;

    FOR v_admin IN
        SELECT id FROM public.profiles
        WHERE role = 'ADMIN' AND is_active = true
    LOOP
        PERFORM public.fn_create_notification(
            v_admin.id,
            'Patrol Baru',
            format('%s membuat temuan baru di %s.', v_reporter, v_location),
            'PATROL_CREATED',
            NEW.id
        );
    END LOOP;

    RETURN NEW;
END;
$$;

CREATE OR REPLACE TRIGGER trg_notify_admin_new_finding
AFTER INSERT ON public.patrol_findings
FOR EACH ROW EXECUTE FUNCTION public.fn_notify_admin_new_finding();

-- Admin handles/closes finding -> notify the creator.
CREATE OR REPLACE FUNCTION public.fn_notify_finding_creator_on_status()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_handler TEXT;
BEGIN
    IF NEW.status IS DISTINCT FROM OLD.status
       AND NEW.status IN ('IN_PROGRESS', 'CLOSED') THEN
        SELECT full_name INTO v_handler
        FROM public.profiles
        WHERE id = COALESCE(NEW.handled_by, auth.uid());

        PERFORM public.fn_create_notification(
            NEW.reported_by,
            CASE WHEN NEW.status = 'CLOSED' THEN 'Patrol Selesai Ditangani' ELSE 'Patrol Sedang Ditangani' END,
            CASE WHEN NEW.status = 'CLOSED'
                 THEN format('Temuan patrol Anda telah ditangani oleh %s.', COALESCE(v_handler, 'Admin'))
                 ELSE format('Temuan patrol Anda sedang ditangani oleh %s.', COALESCE(v_handler, 'Admin'))
            END,
            CASE WHEN NEW.status = 'CLOSED' THEN 'PATROL_CLOSED' ELSE 'PATROL_IN_PROGRESS' END,
            NEW.id
        );
    END IF;
    RETURN NEW;
END;
$$;

CREATE OR REPLACE TRIGGER trg_notify_finding_creator_on_status
AFTER UPDATE OF status ON public.patrol_findings
FOR EACH ROW EXECUTE FUNCTION public.fn_notify_finding_creator_on_status();
