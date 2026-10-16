import 'package:flutter/material.dart';
import '../../../notification/presentation/screens/notification_screen.dart';
import '../../data/models/notification_item_model.dart';

class DashboardNotificationList extends StatelessWidget {
  final List<NotificationItemModel> notifications;
  final Function(NotificationItemModel)? onItemTap;
  final VoidCallback? onRefreshRequested;

  const DashboardNotificationList({
    super.key,
    required this.notifications,
    this.onItemTap,
    this.onRefreshRequested,
  });

  String _formatTimeAgo(DateTime dateTime) {
    final diff = DateTime.now().difference(dateTime);
    if (diff.inSeconds < 60) {
      return 'Baru saja';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes} menit lalu';
    } else if (diff.inHours < 24) {
      return '${diff.inHours} jam lalu';
    } else if (diff.inDays < 7) {
      return '${diff.inDays} hari lalu';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'NOTIFIKASI',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 11,
                color: Color(0xFF64748B),
                letterSpacing: 0.8,
              ),
            ),
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const NotificationScreen(),
                  ),
                ).then((_) {
                  if (onRefreshRequested != null) onRefreshRequested!();
                });
              },
              child: const Text(
                'Lihat semua >',
                style: TextStyle(
                  fontSize: 11,
                  color: Color(0xFF2563EB),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (notifications.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: const Text(
              'Tidak ada notifikasi terbaru',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
            ),
          )
        else
          ...notifications.map((n) {
            final typeLower = n.type.toLowerCase();
            final isPatrol = typeLower.contains('patrol');

            return Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  if (onItemTap != null) {
                    onItemTap!(n);
                  }
                },
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: n.isRead ? Colors.white : const Color(0xFFF0FDF4),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: n.isRead
                          ? const Color(0xFFE2E8F0)
                          : const Color(0xFF86EFAC),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isPatrol
                              ? const Color(0xFFDCFCE7)
                              : const Color(0xFFFEF3C7),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isPatrol
                              ? Icons.assignment_outlined
                              : Icons.calendar_month,
                          color: isPatrol
                              ? Colors.green
                              : Colors.amber.shade800,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    n.title,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: n.isRead
                                          ? FontWeight.bold
                                          : FontWeight.w900,
                                      color: const Color(0xFF1E293B),
                                    ),
                                  ),
                                ),
                                if (!n.isRead)
                                  Container(
                                    margin: const EdgeInsets.only(left: 4),
                                    width: 6,
                                    height: 6,
                                    decoration: const BoxDecoration(
                                      color: Colors.blue,
                                      shape: BoxShape.circle,
                                    ),
                                  )
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              n.message,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 10,
                                color: Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            _formatTimeAgo(n.createdAt),
                            style: const TextStyle(
                                fontSize: 9, color: Color(0xFF94A3B8)),
                          ),
                          const SizedBox(height: 4),
                          const Icon(
                            Icons.chevron_right,
                            size: 16,
                            color: Color(0xFF94A3B8),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
      ],
    );
  }
}