-- 014_seed_master.sql

INSERT INTO public.companies (code, name, address)
VALUES ('BTU', 'PT Bukaka Teknik Utama', 'Workshop A')
ON CONFLICT (code) DO NOTHING;

INSERT INTO public.departments (company_id, code, name, description)
SELECT c.id, src.code, src.name, src.description
FROM public.companies c
CROSS JOIN (VALUES
    ('QA_QC', 'QA / QC Department', 'Quality Assurance & Quality Control'),
    ('PROD', 'Production Department', 'Production / Workshop'),
    ('HSE', 'HSE Department', 'Health, Safety & Environment'),
    ('PPIC', 'PPIC Department', 'Production Planning & Inventory Control'),
    ('MTC', 'Maintenance Department', 'Maintenance & Equipment Service')
) AS src(code, name, description)
WHERE c.code = 'BTU'
ON CONFLICT (code) DO NOTHING;

INSERT INTO public.locations (code, name, location_type, department_id, description, display_order)
SELECT src.code, src.name, 'WORKSHOP'::public.location_type, d.id, src.description, src.display_order
FROM (VALUES
    ('LOC-01', 'Line A', 'PROD', 'Area Workshop Line A', 1),
    ('LOC-02', 'Line B', 'PROD', 'Area Workshop Line B', 2),
    ('LOC-03', 'Line C', 'PROD', 'Area Workshop Line C', 3),
    ('LOC-04', 'Line D-E', 'PROD', 'Area Workshop Line D-E', 4),
    ('LOC-05', 'Line F', 'PROD', 'Area Workshop Line F', 5),
    ('LOC-06', 'Line G', 'PROD', 'Area Workshop Line G', 6),
    ('LOC-07', 'Line Blasting Painting', 'PROD', 'Area Surface Treatment & Painting', 7),
    ('LOC-08', 'Line Corrugated', 'PROD', 'Area Workshop Line Corrugated', 8),
    ('LOC-09', 'Longspan', 'PROD', 'Area Longspan', 9),
    ('LOC-10', 'Stockyard Material & KPS', 'PPIC', 'Area Penyimpanan Material & KPS', 10),
    ('LOC-11', 'Stockyard Packing', 'PPIC', 'Area Penyiapan & Packing Material', 11),
    ('LOC-12', 'Warehouse', 'PPIC', 'Gudang Utama & Penyimpanan', 12),
    ('LOC-13', 'Maintenance Area', 'MTC', 'Area Maintenance & Perbaikan Fasilitas', 13)
) AS src(code, name, dept_code, description, display_order)
JOIN public.departments d ON d.code = src.dept_code
ON CONFLICT (code) DO NOTHING;

INSERT INTO public.app_settings (setting_key, setting_value, description)
VALUES
    ('checklist_passing_grade', '70', 'Passing grade checklist 5S dalam persen'),
    ('schedule_week_count', '4', 'Jumlah minggu dalam satu periode jadwal pada template'),
    ('patrol_day_of_week', '5', 'Hari pelaksanaan patrol mingguan: 1=Senin ... 5=Jumat')
ON CONFLICT (setting_key) DO UPDATE
SET setting_value = EXCLUDED.setting_value,
    updated_at = now();
