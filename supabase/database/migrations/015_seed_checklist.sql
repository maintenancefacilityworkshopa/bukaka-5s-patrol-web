-- 015_seed_checklist.sql

INSERT INTO public.checklist_categories (code, name, description, display_order) VALUES
    ('SEIRI', 'Seiri - Ringkas', 'Pemilahan', 1),
    ('SEITON', 'Seiton - Rapih', 'Penataan', 2),
    ('SEISO', 'Seiso - Resik', 'Pembenahan/Pembersihan', 3),
    ('SEIKETSU', 'Seiketsu - Rawat', 'Pemantapan/Standardisasi', 4),
    ('SHITSUKE', 'Shitsuke - Rajin', 'Pembiasaan/Kedisiplinan', 5)
ON CONFLICT (code) DO UPDATE SET name=EXCLUDED.name, description=EXCLUDED.description, display_order=EXCLUDED.display_order;

INSERT INTO public.checklist_templates (code, name, location_type, form_number, description, version, is_active)
VALUES
    ('HSE-FM-34-OFFICE', 'FORM CHECKLIST 5S (KANTOR)', 'OFFICE', 'HSE-FM-34', 'Checklist 5S untuk area kantor PT Bukaka Teknik Utama', 1, true),
    ('HSE-FM-34-WORKSHOP', 'FORM CHECKLIST 5S (WORKSHOP)', 'WORKSHOP', 'HSE-FM-34', 'Checklist 5S untuk area workshop PT Bukaka Teknik Utama', 1, true)
ON CONFLICT (code) DO UPDATE SET name=EXCLUDED.name, location_type=EXCLUDED.location_type, form_number=EXCLUDED.form_number, description=EXCLUDED.description, is_active=true;

-- 25 checklist items: HSE-FM-34-OFFICE
INSERT INTO public.checklist_items (template_id, category_id, item_number, title, criteria, max_score, is_required, display_order)
SELECT t.id, c.id, v.item_number, v.title, v.criteria, 4, true, v.item_number
FROM public.checklist_templates t
JOIN (VALUES
    ('SEIRI', 1, 'Loker', 'Tidak diperbolehkan terdapat bahan yang tidak terkait dengan aspek pekerjaan (hanya berisi seperti dokumen, gambar, materi, dan hasil pertemuan tertentu)'),
    ('SEIRI', 2, 'Meja', 'Tidak ada bagian dari bahan yang tidak terkait dengan aspek pekerjaan diatas meja atau dalam laci'),
    ('SEIRI', 3, 'Pengendalian visual', 'Barang-barang atau dokumen yang tidak diperlukan telah dipindahkan'),
    ('SEIRI', 4, 'Standard untuk pembuangan', 'Standard untuk pembuangan dokumen dan peralatan ditetapkan'),
    ('SEIRI', 5, 'Papan informasi', 'Papan informasi terkini & relevan untuk bekerja'),
    ('SEITON', 6, 'Label penyimpanan', 'Pelabelan loker dan peralatan memungkinkan identifikasi langsung'),
    ('SEITON', 7, 'Label untuk penyimpanan dan peralatan', 'Segala sesuatu dengan jelas diidentifikasi'),
    ('SEITON', 8, 'Kemudahan penggunaan', 'Tempat penyimpanan dirancang untuk memudahkan penggunaan'),
    ('SEITON', 9, 'Tempat penyimpanan yang teratur', 'Segala sesuatu disimpan pada tempatnya'),
    ('SEITON', 10, 'Lorong dan papan pengumuman', 'Semua garis pembagi dan papan pengumuman jelas terlihat'),
    ('SEISO', 11, 'Lantai', 'Lantai bersih'),
    ('SEISO', 12, 'Debu dan kotoran', 'Jendela, kusen, dan rak bersih'),
    ('SEISO', 13, 'Tanggung kebersihan', 'Terdapat rotasi atau sistem shift untuk kebersihan'),
    ('SEISO', 14, 'Tempat sampah', 'Terdapat sistem untuk membuang kotoran dan sampah kertas'),
    ('SEISO', 15, 'Kebiasaan membersihan', 'Membersihkan meja kerja dianggap sebagai kegiatan rutin'),
    ('SEIKETSU', 16, 'Ventilasi', 'Udara yang bersih, tidak berbau dan bebas dari asap rokok'),
    ('SEIKETSU', 17, 'Pencahayaan', 'Intensitas cahaya yang tepat'),
    ('SEIKETSU', 18, 'Pakaian kerja', 'Tidak ada seorangpun yang memakai pakaian sobek, usang, dan rusak'),
    ('SEIKETSU', 19, 'Lingkungan', 'Lingkungan secara umum baik, termasuk warna, udara, dan cahaya'),
    ('SEIKETSU', 20, '3S pertama', 'Terdapat sistem untuk mempertahankan Sort/ Pemilahan, Set in Order/ Penataa, dan Shine/ Pembersihan'),
    ('SHITSUKE', 21, 'Peraturan berpakaian', 'Peraturan ditaati'),
    ('SHITSUKE', 22, 'Hubungan antar manusia', 'Secara umum terdapat lingkungan yang nyaman, orang yang saling menyapa, dsb'),
    ('SHITSUKE', 23, 'Waktu pertemuan dan waktu istirahat', 'Setiap orang selalu tepat waktu'),
    ('SHITSUKE', 24, 'Reward dan pelanggaran', 'Reward dan pelanggaran sudah diterapkan untuk mendukung disiplin karyawan'),
    ('SHITSUKE', 25, 'Peraturan dan tata tertib', 'Semua peraturan dan tata tertib dengan tegas ditaati')
) AS v(category_code, item_number, title, criteria) ON true
JOIN public.checklist_categories c ON c.code = v.category_code
WHERE t.code = 'HSE-FM-34-OFFICE'
ON CONFLICT (template_id, item_number) DO UPDATE
SET category_id = EXCLUDED.category_id,
    title = EXCLUDED.title,
    criteria = EXCLUDED.criteria,
    max_score = 4,
    is_required = true,
    display_order = EXCLUDED.display_order,
    updated_at = now();

-- 25 checklist items: HSE-FM-34-WORKSHOP
INSERT INTO public.checklist_items (template_id, category_id, item_number, title, criteria, max_score, is_required, display_order)
SELECT t.id, c.id, v.item_number, v.title, v.criteria, 4, true, v.item_number
FROM public.checklist_templates t
JOIN (VALUES
    ('SEIRI', 1, 'Komponen atau bahan', 'Tidak ada persediaan barang atau pekerjaan yang tidak diperlukan di are kerja'),
    ('SEIRI', 2, 'Mesin dan peralatan', 'Semua mesin dan bagian dari peralatan digunakan secara rutin'),
    ('SEIRI', 3, 'Alat kerja', 'Semua alat kerja digunakan secara rutin'),
    ('SEIRI', 4, 'Pengendalian visual', 'Semua barang yang tidak diperlukan dapat langsung terlihat'),
    ('SEIRI', 5, 'Standar untuk pembuangan', 'Ada standar yang jelas untuk membuang kelebihan'),
    ('SEITON', 6, 'Label penyimpanan', 'Ada label-label untuk menunjukan perbedaan wilayah'),
    ('SEITON', 7, 'Label rak dan penyimpanan barang', 'Semua rak dan barang yang disimpan diberi label secara jelas'),
    ('SEITON', 8, 'Indikator jumlah', 'Terdapat penunjukan yang jelas atas jumlah persediaan maksimum dan minimum'),
    ('SEITON', 9, 'Garis pembagi', 'Semua garis pembagi jelas dan dicat warna putih'),
    ('SEITON', 10, 'Alat kerja', 'Tempat penyimpanan alat kerja diatur dengan baik untuk memudahkan pengambilan dan pengembalian alat dan barang'),
    ('SEISO', 11, 'Lantai', 'Lantai bersih dan bebas dari potensi bahaya (air, minyak, bahan kimia, kabel listrik, dsb)'),
    ('SEISO', 12, 'Mesin dan peralatan kerja', 'Mesin dan peralatan kerja selalu dijaga kebersihannya (bebas dari kotoran, kebocoran, dan tumpahan)'),
    ('SEISO', 13, 'Tempat sampah', 'Tempat sampah tersedia, dijaga kebersihannya dan dikosongkan secara teratur'),
    ('SEISO', 14, 'Tanggung jawab kebersihan', 'Terdapat rotasi dan sistem shift untuk kebersihan'),
    ('SEISO', 15, 'Kebiasaan membersihkan', 'Housekeeping area kerja dianggap kegiatan rutin'),
    ('SEIKETSU', 16, 'Informasi dan standar 5S', 'Papan informasi 5S terpasang dan pekerja memahami standar 5S'),
    ('SEIKETSU', 17, 'Pencahayaan', 'Sudut intensitas pencahayaan tepat'),
    ('SEIKETSU', 18, 'Pakaian kerja', 'Tidak ada seorangpun yang memakai pakaian sobek, usang, dan rusak'),
    ('SEIKETSU', 19, 'Menghindarkan', 'Ada perhatian khusus untuk menghindari material bertumpuk'),
    ('SEIKETSU', 20, '3S pertama', 'Terdapat sistem untuk mempertahankan Sort/ Pemilahan, Set in Order/ Penataan, dan Shine/ Pembersihan'),
    ('SHITSUKE', 21, 'Peraturan berpakaian', 'Peraturan di taati dan sesuai dengan standar keselamatan kerja di area tersebut'),
    ('SHITSUKE', 22, 'Hubungan antar manusia', 'Setiap orang terlibat dalam implementasi 5S'),
    ('SHITSUKE', 23, 'Pertemuan dan merokok', 'Setiap orang selalu mencoba untuk tepat waktu dan menaati peraturan merokok'),
    ('SHITSUKE', 24, 'Peraturan dan prosedur', 'Semua peraturan dan prosedur pekerjaan dimengerti dan ditaati'),
    ('SHITSUKE', 25, 'Perhatian terhadap peraturan', 'Semua peraturan dan tata tertib ditaati')
) AS v(category_code, item_number, title, criteria) ON true
JOIN public.checklist_categories c ON c.code = v.category_code
WHERE t.code = 'HSE-FM-34-WORKSHOP'
ON CONFLICT (template_id, item_number) DO UPDATE
SET category_id = EXCLUDED.category_id,
    title = EXCLUDED.title,
    criteria = EXCLUDED.criteria,
    max_score = 4,
    is_required = true,
    display_order = EXCLUDED.display_order,
    updated_at = now();
