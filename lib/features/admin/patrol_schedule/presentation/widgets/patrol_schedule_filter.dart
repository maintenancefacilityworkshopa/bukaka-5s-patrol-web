import 'package:flutter/material.dart';

class PatrolScheduleFilter extends StatelessWidget {
  final String period;
  final String selectedMonth;
  final String selectedYear;
  final int selectedWeek;
  final ValueChanged<String> onPeriodChanged;
  final ValueChanged<String?> onMonthChanged;
  final ValueChanged<String?> onYearChanged;
  final ValueChanged<int> onWeekChanged;

  const PatrolScheduleFilter({
    super.key,
    required this.period,
    required this.selectedMonth,
    required this.selectedYear,
    required this.selectedWeek,
    required this.onPeriodChanged,
    required this.onMonthChanged,
    required this.onYearChanged,
    required this.onWeekChanged,
  });

  static const primaryBlue = Color(0xFF2563EB);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Periode Tampilan',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
          ),
          const SizedBox(height: 12),

          // Toggle Period: Minggu | Bulan | Tahun
          Container(
            height: 38,
            constraints: const BoxConstraints(maxWidth: 320),
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: ['Minggu', 'Bulan', 'Tahun'].map((p) {
                final isSelected = period == p;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => onPeriodChanged(p),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: isSelected ? primaryBlue : Colors.transparent,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            p == 'Minggu'
                                ? Icons.view_week_outlined
                                : p == 'Bulan'
                                    ? Icons.calendar_month_outlined
                                    : Icons.date_range_outlined,
                            size: 15,
                            color: isSelected ? Colors.white : const Color(0xFF64748B),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            p,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: isSelected ? Colors.white : const Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 16),

          // Tukar Penempatan: Minggu ke- di Kiri, Bulan & Tahun di Kanan
          Wrap(
            spacing: 20,
            runSpacing: 12,
            crossAxisAlignment: WrapCrossAlignment.end,
            children: [
              if (period == 'Minggu')
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Minggu ke-',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF64748B)),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: List.generate(4, (i) {
                        final weekNum = i + 1;
                        final isSelected = selectedWeek == weekNum;
                        return GestureDetector(
                          onTap: () => onWeekChanged(weekNum),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            margin: const EdgeInsets.only(right: 8),
                            width: 38,
                            height: 38,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: isSelected ? primaryBlue : Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isSelected ? primaryBlue : const Color(0xFFCBD5E1),
                              ),
                            ),
                            child: Text(
                              '$weekNum',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: isSelected ? Colors.white : const Color(0xFF1E293B),
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                  ],
                ),
              _buildDropdown(
                'Bulan',
                selectedMonth,
                [
                  'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
                  'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
                ],
                onMonthChanged,
              ),
              _buildDropdown(
                'Tahun',
                selectedYear,
                ['2024', '2025', '2026', '2027'],
                onYearChanged,
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Subtext Info Banner
          Row(
            children: const [
              Icon(Icons.info_outline, size: 14, color: Color(0xFF2563EB)),
              SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Patrol 5S hanya dilakukan 1 kali dalam seminggu yaitu setiap hari Jumat.',
                  style: TextStyle(fontSize: 11, color: Color(0xFF2563EB), fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown(
    String label,
    String value,
    List<String> items,
    ValueChanged<String?> onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF64748B)),
        ),
        const SizedBox(height: 6),
        Container(
          height: 38,
          constraints: const BoxConstraints(minWidth: 120),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFCBD5E1)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: items.contains(value) ? value : items.first,
              icon: const Icon(Icons.keyboard_arrow_down, size: 18, color: Color(0xFF64748B)),
              style: const TextStyle(fontSize: 12, color: Color(0xFF1E293B), fontWeight: FontWeight.w600),
              items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }
}