import 'package:flutter/material.dart';

class ActivityLogModel {
  final String action;
  final String code;
  final String location;
  final String time;
  final String status;
  final DateTime createdAt;
  final IconData icon;
  final Color iconColor;
  final Color iconBgColor;

  ActivityLogModel({
    required this.action,
    required this.code,
    required this.location,
    required this.time,
    required this.status,
    required this.createdAt,
    required this.icon,
    required this.iconColor,
    required this.iconBgColor,
  });

  factory ActivityLogModel.fromMap(Map<String, dynamic> map, String timeFormatted) {
    // 1. Parsing Kode Patrol dari kode_patrol / details JSON / fallback
    String rawCode = map['kode_patrol']?.toString() ??
        map['code']?.toString() ??
        map['patrol_code']?.toString() ??
        'NP-2026-0001';

    if (map['details'] != null && map['details'] is Map) {
      final detailsMap = map['details'] as Map;
      if (detailsMap['kode_patrol'] != null) {
        rawCode = detailsMap['kode_patrol'].toString();
      } else if (detailsMap['code'] != null) {
        rawCode = detailsMap['code'].toString();
      }
    }

    if (rawCode.contains('SK-')) {
      rawCode = rawCode.replaceAll('SK-', 'NP-');
    }

    final RegExp regExp3 = RegExp(r'NP-(\d{4})-(\d{3})$');
    if (regExp3.hasMatch(rawCode)) {
      rawCode = rawCode.replaceAllMapped(regExp3, (match) => 'NP-${match[1]}-0${match[2]}');
    }

    // 2. Pembersihan Teks Action dari snake_case menjadi Kalimat Natural
    final String rawAction = (map['action']?.toString() ?? map['title']?.toString() ?? '').toUpperCase();
    final String statusStr = (map['status']?.toString() ?? '').toUpperCase();

    String formattedAction = 'Aktivitas Patroli';
    IconData iconData = Icons.assignment_outlined;
    Color iconColor = const Color(0xFF2563EB);
    Color iconBgColor = const Color(0xFFEFF6FF);

    if (rawAction.contains('CREATE') || rawAction.contains('BUAT')) {
      formattedAction = 'Membuat Patroli Baru';
      iconData = Icons.add_task_rounded;
      iconColor = const Color(0xFF2563EB);
      iconBgColor = const Color(0xFFEFF6FF);
    } else if (rawAction.contains('UPDATE') || rawAction.contains('PERBARUI') || rawAction.contains('EDIT')) {
      formattedAction = 'Patroli Diperbarui';
      iconData = Icons.edit_note_rounded;
      iconColor = const Color(0xFFD97706);
      iconBgColor = const Color(0xFFFEF3C7);
    } else if (statusStr == 'CLOSED' || statusStr == 'COMPLETED' || statusStr == 'SELESAI') {
      formattedAction = 'Patroli Selesai';
      iconData = Icons.check_circle_rounded;
      iconColor = const Color(0xFF16A34A);
      iconBgColor = const Color(0xFFF0FDF4);
    } else if (statusStr == 'OPEN' || statusStr == 'PENDING') {
      formattedAction = 'Peringatan Patroli Open';
      iconData = Icons.warning_amber_rounded;
      iconColor = const Color(0xFFDC2626);
      iconBgColor = const Color(0xFFFEF2F2);
    }

    return ActivityLogModel(
      action: formattedAction,
      code: rawCode,
      location: map['location']?.toString() ?? map['lokasi']?.toString() ?? 'Maintenance Area',
      time: timeFormatted,
      status: map['status']?.toString() ?? 'OPEN',
      createdAt: _parseUtcToLocal(map['created_at']?.toString()),
      icon: iconData,
      iconColor: iconColor,
      iconBgColor: iconBgColor,
    );
  }

  static DateTime _parseUtcToLocal(String? raw) {
    if (raw == null || raw.isEmpty) return DateTime.now();
    try {
      final parsed = DateTime.parse(raw);
      return parsed.isUtc ? parsed.toLocal() : parsed;
    } catch (_) {
      return DateTime.now();
    }
  }
}