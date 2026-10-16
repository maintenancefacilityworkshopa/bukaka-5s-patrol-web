import 'package:excel/excel.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PatrolScheduleService {
  final SupabaseClient _supabase = Supabase.instance.client;

  String _formatDate(DateTime date) {
    return "${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
  }

  /// 1. Stream jadwal berdasarkan filter bulan dan tahun lengkap dengan detail relasi
  Stream<List<Map<String, dynamic>>> streamSchedulesByFilter({
    dynamic month,
    dynamic year,
    dynamic period,
    dynamic week,
  }) {
    // Menggunakan stream Supabase untuk menyimak perubahan tabel 'schedules'
    var query = _supabase.from('schedules').stream(primaryKey: ['id']);

    return query.asyncMap((list) async {
      // Filter jadwal berdasarkan rentang bulan & tahun
      final filteredList = list.where((item) {
        if (item['start_date'] == null) return false;
        final startDate = DateTime.tryParse(item['start_date'].toString());
        if (startDate == null) return false;

        bool matchMonth = true;
        bool matchYear = true;

        if (month != null) {
          final mStr = month.toString().toLowerCase();
          matchMonth = startDate.month.toString() == mStr ||
              _getMonthName(startDate.month).toLowerCase() == mStr;
        }

        if (year != null) {
          matchYear = startDate.year.toString() == year.toString();
        }

        return matchMonth && matchYear;
      }).toList();

      // Ambil detail penugasan (schedule_details) untuk setiap schedule secara terpisah
      List<Map<String, dynamic>> resultList = [];
      for (var schedule in filteredList) {
        final scheduleId = schedule['id'];
        
        // Fetch detail relasi
        final detailsRes = await _supabase
            .from('schedule_details')
            .select('location_id, user_id')
            .eq('schedule_id', scheduleId);

        final detailsList = List<Map<String, dynamic>>.from(detailsRes);

        // Buat gabungan map agar menyertakan schedule_details
        Map<String, dynamic> merged = Map<String, dynamic>.from(schedule);
        merged['schedule_details'] = detailsList;
        resultList.add(merged);
      }

      return resultList;
    });
  }

  String _getMonthName(int month) {
    const months = [
      'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
    ];
    return months[month - 1];
  }

  Future<void> saveSchedule({
    String? id,
    required String title,
    required String description,
    required DateTime startDate,
    required DateTime endDate,
    bool isActive = true,
  }) async {
    final payload = {
      'title': title,
      'description': description,
      'start_date': _formatDate(startDate),
      'end_date': _formatDate(endDate),
      'is_active': isActive,
    };

    if (id != null && id.isNotEmpty) {
      await _supabase.from('schedules').update(payload).eq('id', id);
    } else {
      await _supabase.from('schedules').insert(payload);
    }
  }

  Future<void> deleteSchedule(String id) async {
    await _supabase.from('schedule_details').delete().eq('schedule_id', id);
    await _supabase.from('schedules').delete().eq('id', id);
  }

  /// 4. Import Excel Schedule dengan Pemetaan Kolom Minggu Presisi (M1 - M4)
  Future<void> importScheduleFromExcel({
    required List<int> bytes,
    required String title,
    required DateTime startDate,
    required DateTime endDate,
    String selectedMonth = 'September',
    void Function(double progress, String statusMessage)? onProgress,
  }) async {
    try {
      debugPrint('=== MULAI IMPORT EXCEL (MODE PRESISI KOLOM MINGGU) ===');
      onProgress?.call(0.05, 'Membaca file Excel...');

      final excel = Excel.decodeBytes(bytes);

      onProgress?.call(0.15, 'Membuat jadwal utama...');
      final scheduleRes = await _supabase.from('schedules').insert({
        'title': title,
        'description': 'Jadwal Patroli Bulanan 5S',
        'start_date': _formatDate(startDate),
        'end_date': _formatDate(endDate),
        'is_active': true,
      }).select().single();

      final String scheduleId = scheduleRes['id'];

      onProgress?.call(0.25, 'Mengambil data master dari database...');
      final profilesRes = await _supabase.from('profiles').select('id, full_name');
      final locationsRes = await _supabase.from('locations').select('id, name');

      List<Map<String, dynamic>> scheduleDetailsToInsert = [];

      String sheetName = excel.tables.keys.firstWhere(
        (k) {
          final keyLower = k.toLowerCase();
          final monthLower = selectedMonth.toLowerCase();
          final shortMonth = monthLower.length >= 3 ? monthLower.substring(0, 3) : monthLower;
          return keyLower.contains(monthLower) || keyLower.contains(shortMonth);
        },
        orElse: () => excel.tables.keys.first,
      );

      final sheet = excel.tables[sheetName];
      if (sheet == null) {
        onProgress?.call(1.0, 'Sheet tidak ditemukan.');
        return;
      }

      String? currentLocId;
      int totalRows = sheet.maxRows;

      for (int rowIndex = 0; rowIndex < totalRows; rowIndex++) {
        final double currentProgress = 0.30 + ((rowIndex / totalRows) * 0.50);
        onProgress?.call(
          currentProgress,
          'Memproses baris ${rowIndex + 1} dari $totalRows...',
        );

        final row = sheet.rows[rowIndex];
        if (row.isEmpty) continue;

        // 1. Cari Nama Lokasi di Seleluruh Kolom
        for (int colIdx = 0; colIdx < row.length; colIdx++) {
          final cellValue = row[colIdx]?.value?.toString().trim() ?? '';
          if (cellValue.isEmpty || cellValue.length < 2) continue;

          final matchedLoc = locationsRes.firstWhere(
            (l) {
              final dbName = l['name'].toString().toLowerCase().trim();
              final excelName = cellValue.toLowerCase().trim();
              return dbName == excelName || dbName.replaceAll(' ', '') == excelName.replaceAll(' ', '');
            },
            orElse: () => {},
          );

          if (matchedLoc.isNotEmpty) {
            currentLocId = matchedLoc['id'];
            break;
          }
        }

        // 2. Jika Lokasi Aktif, Cari Petugas berdasarkan Indeks Kolom Minggu
        if (currentLocId != null) {
          for (int colIdx = 0; colIdx < row.length; colIdx++) {
            final cellValue = row[colIdx]?.value?.toString().trim() ?? '';
            if (cellValue.isEmpty || cellValue.length < 3) continue;

            final matchedUser = profilesRes.firstWhere(
              (p) {
                final dbFullName = p['full_name'].toString().toLowerCase().trim();
                final targetName = cellValue.toLowerCase().trim();
                return dbFullName == targetName ||
                       (targetName.length > 3 && dbFullName.contains(targetName));
              },
              orElse: () => {},
            );

            if (matchedUser.isNotEmpty) {
              // Penentuan Minggu Berdasarkan Indeks Kolom
              int weekNumber = 1;
              if (colIdx >= 32) {
                weekNumber = 4; // AG - AN
              } else if (colIdx >= 24) {
                weekNumber = 3; // Y - AF
              } else if (colIdx >= 16) {
                weekNumber = 2; // Q - X
              } else if (colIdx >= 8) {
                weekNumber = 1; // I - P
              }

              // Hindari duplikasi insert data yang sama di baris yang sama
              bool isDuplicate = scheduleDetailsToInsert.any((element) =>
                  element['schedule_id'] == scheduleId &&
                  element['location_id'] == currentLocId &&
                  element['user_id'] == matchedUser['id'] &&
                  element['week_number'] == weekNumber);

              if (!isDuplicate) {
                scheduleDetailsToInsert.add({
                  'schedule_id': scheduleId,
                  'location_id': currentLocId,
                  'user_id': matchedUser['id'],
                  'week_number': weekNumber,
                  'shift_order': 1,
                });
              }
            }
          }
        }
      }

      // 3. Simpan Ke Supabase
      if (scheduleDetailsToInsert.isNotEmpty) {
        onProgress?.call(0.85, 'Menyimpan data detail ke database...');
        await _supabase.from('schedule_details').insert(scheduleDetailsToInsert);
        onProgress?.call(1.0, 'Import Selesai!');
      } else {
        onProgress?.call(1.0, 'Selesai: Tidak ada data yang cocok.');
      }
    } catch (e) {
      debugPrint('🚨 Error Import: $e');
      rethrow;
    }
  }
}