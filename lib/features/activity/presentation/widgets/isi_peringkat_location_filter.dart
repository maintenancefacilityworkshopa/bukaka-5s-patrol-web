import 'package:flutter/material.dart';
import '../../data/models/location_ranking_model.dart';

class IsiPeringkatLocationFilter extends StatelessWidget {
  final List<LocationRankingModel> rankings;
  final ValueChanged<String>? onLocationTap;

  const IsiPeringkatLocationFilter({
    super.key,
    required this.rankings,
    this.onLocationTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 4, bottom: 10),
          child: Text(
            'List Peringkat Location',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Color(0xFF475569),
            ),
          ),
        ),
        if (rankings.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: const Center(
              child: Text(
                'Belum ada data lokasi terdaftar',
                style: TextStyle(fontSize: 12.5, color: Color(0xFF64748B)),
              ),
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: rankings.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final item = rankings[index];
              final displayTitle = item.locationDescription.isNotEmpty
                  ? item.locationDescription
                  : item.locationName;

              final Color badgeColor = _getRankBadgeColor(item.rank);
              final Color badgeBg = _getRankBgColor(item.rank);

              return InkWell(
                onTap: onLocationTap != null
                    ? () => onLocationTap!(item.locationName)
                    : null,
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: item.rank <= 3 && item.totalPatrol > 0
                          ? badgeColor.withValues(alpha: 0.35)
                          : const Color(0xFFE2E8F0),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.02),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: badgeBg,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          '#${item.rank}',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: badgeColor,
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '# ${item.rank} $displayTitle',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Total Patrol Sebanyak ${item.totalPatrol} Temuan',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF475569),
                              ),
                            ),
                            if (item.totalPatrol > 0) ...[
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  _buildMiniPill('Open: ${item.openCount}',
                                      const Color(0xFFDC2626)),
                                  const SizedBox(width: 6),
                                  _buildMiniPill(
                                      'Progress: ${item.inProgressCount}',
                                      const Color(0xFFD97706)),
                                  const SizedBox(width: 6),
                                  _buildMiniPill('Selesai: ${item.closedCount}',
                                      const Color(0xFF059669)),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.chevron_right_rounded,
                        color: Color(0xFF94A3B8),
                        size: 20,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
      ],
    );
  }

  Widget _buildMiniPill(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Color _getRankBadgeColor(int rank) {
    if (rank == 1) return const Color(0xFFDC2626);
    if (rank == 2) return const Color(0xFFD97706);
    if (rank == 3) return const Color(0xFF2563EB);
    return const Color(0xFF64748B);
  }

  Color _getRankBgColor(int rank) {
    if (rank == 1) return const Color(0xFFFEF2F2);
    if (rank == 2) return const Color(0xFFFFFBEB);
    if (rank == 3) return const Color(0xFFEFF6FF);
    return const Color(0xFFF1F5F9);
  }
}