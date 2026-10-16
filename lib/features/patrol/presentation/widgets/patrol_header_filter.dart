import 'package:flutter/material.dart';

enum SortOption { terbaru, terdahulu, alfabetAsc, alfabetDesc }

class PatrolHeaderFilter extends StatelessWidget {
  final ValueChanged<String> onSearchChanged;
  final String selectedStatus;
  final List<String> statusOptions;
  final ValueChanged<String?> onStatusChanged;
  final String selectedLokasi;
  final List<String> lokasiOptions;
  final ValueChanged<String?> onLokasiChanged;
  final SortOption selectedSort;
  final ValueChanged<SortOption> onSortChanged;

  const PatrolHeaderFilter({
    super.key,
    required this.onSearchChanged,
    required this.selectedStatus,
    required this.statusOptions,
    required this.onStatusChanged,
    required this.selectedLokasi,
    required this.lokasiOptions,
    required this.onLokasiChanged,
    required this.selectedSort,
    required this.onSortChanged,
  });

  void _showRightPopupMenu(BuildContext context, TapDownDetails details) async {
    final RenderBox overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox;
    const primaryBlue = Color(0xFF2563EB);

    final selected = await showMenu<SortOption>(
      context: context,
      position: RelativeRect.fromRect(
        details.globalPosition & const Size(40, 40),
        Offset.zero & overlay.size,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 6,
      items: [
        const PopupMenuItem<SortOption>(
          enabled: false,
          height: 32,
          child: Text(
            'Urutkan Berdasarkan',
            style: TextStyle(
                fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey),
          ),
        ),
        const PopupMenuDivider(height: 8),
        _buildPopupMenuItem('Terbaru (Default)', SortOption.terbaru, primaryBlue),
        _buildPopupMenuItem('Terdahulu', SortOption.terdahulu, primaryBlue),
        _buildPopupMenuItem(
            'Abjad Lokasi (A - Z)', SortOption.alfabetAsc, primaryBlue),
        _buildPopupMenuItem(
            'Abjad Lokasi (Z - A)', SortOption.alfabetDesc, primaryBlue),
      ],
    );

    if (selected != null) {
      onSortChanged(selected);
    }
  }

  PopupMenuItem<SortOption> _buildPopupMenuItem(
      String title, SortOption value, Color activeColor) {
    final isSelected = selectedSort == value;
    return PopupMenuItem<SortOption>(
      value: value,
      height: 40,
      child: Row(
        children: [
          Icon(
            isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
            size: 18,
            color: isSelected ? activeColor : Colors.grey,
          ),
          const SizedBox(width: 10),
          Text(
            title,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              color: isSelected ? activeColor : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF2563EB), // Header Warna Biru
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(18), // Melengkung di Bagian Bawah
        ),
      ),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: Column(
        children: [
          // Row Search Field + Filter Button
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF9FAFB),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: TextField(
                    onChanged: onSearchChanged,
                    style: const TextStyle(fontSize: 13, color: Colors.black87),
                    decoration: const InputDecoration(
                      hintText: 'Cari lokasi, item, deskripsi...',
                      hintStyle:
                          TextStyle(fontSize: 13, color: Color(0xFF9CA3AF)),
                      prefixIcon: Icon(Icons.search,
                          size: 20, color: Color(0xFF4B5563)),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              GestureDetector(
                onTapDown: (details) => _showRightPopupMenu(context, details),
                child: Container(
                  height: 44,
                  width: 44,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.filter_list_rounded,
                    color: Colors.black87,
                    size: 24,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Row Dropdown Status & Lokasi
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 42,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: statusOptions.contains(selectedStatus)
                          ? selectedStatus
                          : statusOptions.first,
                      isExpanded: true,
                      icon: const Icon(Icons.keyboard_arrow_down,
                          color: Colors.black87),
                      items: statusOptions.map((status) {
                        return DropdownMenuItem(
                          value: status,
                          child: Text(
                            status,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                        );
                      }).toList(),
                      onChanged: onStatusChanged,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Container(
                  height: 42,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: lokasiOptions.contains(selectedLokasi)
                          ? selectedLokasi
                          : lokasiOptions.first,
                      isExpanded: true,
                      icon: const Icon(Icons.keyboard_arrow_down,
                          color: Colors.black87),
                      items: lokasiOptions.map((lokasi) {
                        return DropdownMenuItem(
                          value: lokasi,
                          child: Text(
                            lokasi,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                        );
                      }).toList(),
                      onChanged: onLokasiChanged,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}