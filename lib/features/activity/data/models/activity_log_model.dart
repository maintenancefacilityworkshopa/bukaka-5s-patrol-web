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
  final dynamic rawPatrolData;

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
    this.rawPatrolData,
  });

  factory ActivityLogModel.fromMap(
    Map<String, dynamic> map,
    String timeFormatted, {
    dynamic rawPatrolData,
  }) {
    final details = map['details'] is Map ? map['details'] as Map : {};
    
    // Prioritaskan mengambil kode_patrol resmi dari data patroli linked
    String rawCode = (rawPatrolData != null && rawPatrolData['kode_patrol'] != null)
        ? rawPatrolData['kode_patrol'].toString()
        : (details['kode_patrol']?.toString() ?? map['kode_patrol']?.toString() ?? '-');

    if (rawCode.contains('SK-')) {
      rawCode = rawCode.replaceAll('SK-', 'NP-');
    }

    final String statusStr = (rawPatrolData != null && rawPatrolData['status'] != null)
        ? rawPatrolData['status'].toString().toUpperCase()
        : (details['status'] ?? map['status'] ?? 'OPEN').toString().toUpperCase();

    final bool isClosed = statusStr == 'CLOSED' || statusStr == 'COMPLETED' || statusStr == 'SELESAI';

    String actionText = 'Patroli Diperbarui';
    final rawAction = (map['action'] ?? '').toString().toUpperCase();

    if (rawAction.contains('CREATE') || rawAction.contains('BUAT')) {
      actionText = 'Membuat Patroli Baru';
    } else if (isClosed || rawAction.contains('COMPLETE') || rawAction.contains('SELESAI')) {
      actionText = 'Patroli Selesai';
    } else if (rawAction.contains('DELETE') || rawAction.contains('HAPUS')) {
      actionText = 'Patroli Dihapus';
    } else if (details['description'] != null && details['description'].toString().trim().isNotEmpty) {
      actionText = details['description'].toString();
    }

    // IKON & WIDGET STYLING
    IconData iconData = Icons.published_with_changes_rounded;
    Color iconColor = const Color(0xFFD97706); // Amber
    Color iconBgColor = const Color(0xFFFFFBEB);

    if (isClosed) {
      iconData = Icons.task_alt_rounded;
      iconColor = const Color(0xFF059669); // Emerald
      iconBgColor = const Color(0xFFECFDF5);
    } else if (actionText.contains('Dihapus')) {
      iconData = Icons.delete_sweep_rounded;
      iconColor = const Color(0xFFE11D48); // Rose
      iconBgColor = const Color(0xFFFFF1F2);
    } else if (actionText.contains('Membuat')) {
      iconData = Icons.add_circle_outline_rounded;
      iconColor = const Color(0xFF2563EB); // Blue
      iconBgColor = const Color(0xFFEFF6FF);
    }

    String locationText = 'Area Pabrik';
    if (rawPatrolData != null && rawPatrolData['lokasi'] != null && rawPatrolData['lokasi'].toString().isNotEmpty) {
      locationText = rawPatrolData['lokasi'].toString();
    } else if (map['area_location'] != null && map['area_location'].toString().isNotEmpty) {
      locationText = map['area_location'].toString();
    }

    return ActivityLogModel(
      action: actionText,
      code: rawCode,
      location: locationText,
      time: timeFormatted,
      status: statusStr,
      createdAt: _parseUtcToLocal(map['created_at']?.toString()),
      icon: iconData,
      iconColor: iconColor,
      iconBgColor: iconBgColor,
      rawPatrolData: rawPatrolData ?? map,
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