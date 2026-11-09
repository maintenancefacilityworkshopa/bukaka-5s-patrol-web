// lib/features/notification/data/models/notification_model.dart
import 'package:flutter/material.dart';

class NotificationModel {
  final String id;
  final String? userId;
  final String title;
  final String message;
  final String type; // 'patrol', 'profile', 'system'
  final String? referenceId;
  final bool isRead;
  final DateTime createdAt;

  NotificationModel({
    required this.id,
    this.userId,
    required this.title,
    required this.message,
    required this.type,
    this.referenceId,
    this.isRead = false,
    required this.createdAt,
  });

  factory NotificationModel.fromMap(Map<String, dynamic> map) {
    return NotificationModel(
      id: map['id']?.toString() ?? '',
      userId: map['user_id']?.toString(),
      title: map['title']?.toString() ?? 'Pemberitahuan',
      message: map['message']?.toString() ?? '',
      type: (map['type']?.toString() ?? 'system').toLowerCase(),
      referenceId: map['reference_id']?.toString(),
      isRead: map['is_read'] as bool? ?? false,
      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at'].toString())?.toLocal() ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id.isNotEmpty) 'id': id,
      if (userId != null) 'user_id': userId,
      'title': title,
      'message': message,
      'type': type,
      if (referenceId != null) 'reference_id': referenceId,
      'is_read': isRead,
      'created_at': createdAt.toIso8601String(),
    };
  }

  IconData get iconData {
    if (type.contains('patrol')) {
      return Icons.assignment_turned_in_rounded;
    } else if (type.contains('profile') || type.contains('edit')) {
      return Icons.person_outline_rounded;
    } else if (type.contains('system') || type.contains('sistem')) {
      return Icons.info_outline_rounded;
    } else {
      return Icons.notifications_active_rounded;
    }
  }

  Color get iconColor {
    if (type.contains('patrol')) {
      return const Color(0xFF16A34A); // Emerald
    } else if (type.contains('profile') || type.contains('edit')) {
      return const Color(0xFF2563EB); // Royal Blue
    } else if (type.contains('system') || type.contains('sistem')) {
      return const Color(0xFFD97706); // Amber
    } else {
      return const Color(0xFF475569); // Slate
    }
  }

  Color get iconBgColor {
    if (type.contains('patrol')) {
      return const Color(0xFFDCFCE7);
    } else if (type.contains('profile') || type.contains('edit')) {
      return const Color(0xFFEFF6FF);
    } else if (type.contains('system') || type.contains('sistem')) {
      return const Color(0xFFFEF3C7);
    } else {
      return const Color(0xFFF1F5F9);
    }
  }
}