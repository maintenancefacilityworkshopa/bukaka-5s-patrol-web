-- 013_rls.sql

ALTER TABLE public.companies ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.departments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.locations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.checklist_categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.checklist_templates ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.checklist_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.app_settings ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.schedule_periods ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.schedule_weeks ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.schedule_assignments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.schedule_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.schedule_imports ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.inspection_runs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.inspection_inspectors ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.inspection_results ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.patrol_findings ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.patrol_finding_actions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.activity_logs ENABLE ROW LEVEL SECURITY;

-- MASTER DATA
CREATE POLICY "authenticated read companies" ON public.companies FOR SELECT TO authenticated USING (true);
CREATE POLICY "admin manage companies" ON public.companies FOR ALL TO authenticated USING (public.fn_get_my_role() = 'ADMIN') WITH CHECK (public.fn_get_my_role() = 'ADMIN');

CREATE POLICY "authenticated read departments" ON public.departments FOR SELECT TO authenticated USING (true);
CREATE POLICY "admin manage departments" ON public.departments FOR ALL TO authenticated USING (public.fn_get_my_role() = 'ADMIN') WITH CHECK (public.fn_get_my_role() = 'ADMIN');

CREATE POLICY "authenticated read locations" ON public.locations FOR SELECT TO authenticated USING (true);
CREATE POLICY "admin manage locations" ON public.locations FOR ALL TO authenticated USING (public.fn_get_my_role() = 'ADMIN') WITH CHECK (public.fn_get_my_role() = 'ADMIN');

CREATE POLICY "authenticated read categories" ON public.checklist_categories FOR SELECT TO authenticated USING (true);
CREATE POLICY "admin manage categories" ON public.checklist_categories FOR ALL TO authenticated USING (public.fn_get_my_role() = 'ADMIN') WITH CHECK (public.fn_get_my_role() = 'ADMIN');

CREATE POLICY "authenticated read templates" ON public.checklist_templates FOR SELECT TO authenticated USING (true);
CREATE POLICY "admin manage templates" ON public.checklist_templates FOR ALL TO authenticated USING (public.fn_get_my_role() = 'ADMIN') WITH CHECK (public.fn_get_my_role() = 'ADMIN');

CREATE POLICY "authenticated read checklist items" ON public.checklist_items FOR SELECT TO authenticated USING (true);
CREATE POLICY "admin manage checklist items" ON public.checklist_items FOR ALL TO authenticated USING (public.fn_get_my_role() = 'ADMIN') WITH CHECK (public.fn_get_my_role() = 'ADMIN');

CREATE POLICY "authenticated read settings" ON public.app_settings FOR SELECT TO authenticated USING (true);
CREATE POLICY "admin manage settings" ON public.app_settings FOR ALL TO authenticated USING (public.fn_get_my_role() = 'ADMIN') WITH CHECK (public.fn_get_my_role() = 'ADMIN');

-- PROFILES / USER MANAGEMENT
CREATE POLICY "authenticated read profiles" ON public.profiles FOR SELECT TO authenticated USING (true);
CREATE POLICY "user update own profile" ON public.profiles
FOR UPDATE TO authenticated
USING (id = auth.uid())
WITH CHECK (id = auth.uid() AND role = public.fn_get_my_role() AND is_active = true);
CREATE POLICY "admin manage profiles" ON public.profiles
FOR ALL TO authenticated
USING (public.fn_get_my_role() = 'ADMIN')
WITH CHECK (public.fn_get_my_role() = 'ADMIN');

-- SCHEDULE: read for authenticated, write only Admin.
CREATE POLICY "authenticated read schedule periods" ON public.schedule_periods FOR SELECT TO authenticated USING (true);
CREATE POLICY "admin manage schedule periods" ON public.schedule_periods
FOR ALL TO authenticated
USING (public.fn_get_my_role() = 'ADMIN')
WITH CHECK (public.fn_get_my_role() = 'ADMIN');

CREATE POLICY "authenticated read schedule weeks" ON public.schedule_weeks FOR SELECT TO authenticated USING (true);
CREATE POLICY "admin manage schedule weeks" ON public.schedule_weeks
FOR ALL TO authenticated
USING (public.fn_get_my_role() = 'ADMIN')
WITH CHECK (public.fn_get_my_role() = 'ADMIN');

CREATE POLICY "authenticated read schedule assignments" ON public.schedule_assignments FOR SELECT TO authenticated USING (true);
CREATE POLICY "admin manage schedule assignments" ON public.schedule_assignments
FOR ALL TO authenticated
USING (public.fn_get_my_role() = 'ADMIN')
WITH CHECK (public.fn_get_my_role() = 'ADMIN');

CREATE POLICY "authenticated read schedule members" ON public.schedule_members FOR SELECT TO authenticated USING (true);
CREATE POLICY "admin manage schedule members" ON public.schedule_members
FOR ALL TO authenticated
USING (public.fn_get_my_role() = 'ADMIN')
WITH CHECK (public.fn_get_my_role() = 'ADMIN');

CREATE POLICY "admin manage schedule imports" ON public.schedule_imports
FOR ALL TO authenticated
USING (public.fn_get_my_role() = 'ADMIN')
WITH CHECK (public.fn_get_my_role() = 'ADMIN');

-- INSPECTION / CHECKLIST
CREATE POLICY "authenticated read inspections" ON public.inspection_runs FOR SELECT TO authenticated USING (true);
CREATE POLICY "staff create own inspections" ON public.inspection_runs
FOR INSERT TO authenticated
WITH CHECK (
    created_by = auth.uid()
    AND public.fn_get_my_role() IN ('STAFF_AHLI', 'STAFF_INTERNSHIP')
);
CREATE POLICY "staff update own draft inspections" ON public.inspection_runs
FOR UPDATE TO authenticated
USING (created_by = auth.uid() AND status = 'DRAFT')
WITH CHECK (created_by = auth.uid() AND status IN ('DRAFT', 'SUBMITTED'));
CREATE POLICY "admin manage inspections" ON public.inspection_runs
FOR ALL TO authenticated
USING (public.fn_get_my_role() = 'ADMIN')
WITH CHECK (public.fn_get_my_role() = 'ADMIN');

CREATE POLICY "authenticated read inspection inspectors" ON public.inspection_inspectors FOR SELECT TO authenticated USING (true);
CREATE POLICY "staff manage own inspection inspectors" ON public.inspection_inspectors
FOR ALL TO authenticated
USING (EXISTS (SELECT 1 FROM public.inspection_runs ir WHERE ir.id = inspection_id AND ir.created_by = auth.uid()))
WITH CHECK (EXISTS (SELECT 1 FROM public.inspection_runs ir WHERE ir.id = inspection_id AND ir.created_by = auth.uid()));
CREATE POLICY "admin manage inspection inspectors" ON public.inspection_inspectors
FOR ALL TO authenticated
USING (public.fn_get_my_role() = 'ADMIN')
WITH CHECK (public.fn_get_my_role() = 'ADMIN');

CREATE POLICY "authenticated read inspection results" ON public.inspection_results FOR SELECT TO authenticated USING (true);
CREATE POLICY "staff manage own inspection results" ON public.inspection_results
FOR ALL TO authenticated
USING (EXISTS (SELECT 1 FROM public.inspection_runs ir WHERE ir.id = inspection_id AND ir.created_by = auth.uid() AND ir.status = 'DRAFT'))
WITH CHECK (EXISTS (SELECT 1 FROM public.inspection_runs ir WHERE ir.id = inspection_id AND ir.created_by = auth.uid() AND ir.status = 'DRAFT'));
CREATE POLICY "admin manage inspection results" ON public.inspection_results
FOR ALL TO authenticated
USING (public.fn_get_my_role() = 'ADMIN')
WITH CHECK (public.fn_get_my_role() = 'ADMIN');

-- PATROL FINDINGS: Staff creates, Admin handles.
CREATE POLICY "authenticated read patrol findings" ON public.patrol_findings FOR SELECT TO authenticated USING (true);
CREATE POLICY "staff create own patrol findings" ON public.patrol_findings
FOR INSERT TO authenticated
WITH CHECK (
    reported_by = auth.uid()
    AND public.fn_get_my_role() IN ('STAFF_AHLI', 'STAFF_INTERNSHIP')
    AND status = 'OPEN'
);
CREATE POLICY "admin manage patrol findings" ON public.patrol_findings
FOR ALL TO authenticated
USING (public.fn_get_my_role() = 'ADMIN')
WITH CHECK (public.fn_get_my_role() = 'ADMIN');

CREATE POLICY "authenticated read patrol actions" ON public.patrol_finding_actions FOR SELECT TO authenticated USING (true);
CREATE POLICY "admin manage patrol actions" ON public.patrol_finding_actions
FOR ALL TO authenticated
USING (public.fn_get_my_role() = 'ADMIN')
WITH CHECK (public.fn_get_my_role() = 'ADMIN');

-- NOTIFICATIONS
CREATE POLICY "user read own notifications" ON public.notifications
FOR SELECT TO authenticated USING (user_id = auth.uid());
CREATE POLICY "user update own notifications" ON public.notifications
FOR UPDATE TO authenticated USING (user_id = auth.uid()) WITH CHECK (user_id = auth.uid());

-- ACTIVITY LOGS
CREATE POLICY "authenticated read activity logs" ON public.activity_logs FOR SELECT TO authenticated USING (true);
CREATE POLICY "authenticated insert activity logs" ON public.activity_logs FOR INSERT TO authenticated WITH CHECK (user_id = auth.uid());

-- SECURITY DEFINER helper must not be callable as a public notification factory.
REVOKE EXECUTE ON FUNCTION public.fn_create_notification(UUID, TEXT, TEXT, TEXT, UUID) FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.fn_get_my_role() TO authenticated;
GRANT EXECUTE ON FUNCTION public.fn_calculate_inspection_score(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION public.fn_get_user_dashboard_stats(UUID) TO authenticated;
