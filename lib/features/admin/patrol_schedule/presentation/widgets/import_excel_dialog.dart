import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../../data/patrol_schedule_service.dart';

class ImportExcelDialog extends StatefulWidget {
  const ImportExcelDialog({super.key});

  @override
  State<ImportExcelDialog> createState() => _ImportExcelDialogState();
}

class _ImportExcelDialogState extends State<ImportExcelDialog> {
  final PatrolScheduleService _service = PatrolScheduleService();

  int _currentStep = 1;
  PlatformFile? _selectedFile;
  bool _isLoading = false;

  // State untuk indikator transparan loading bar
  double _importProgress = 0.0;
  String _statusMessage = 'Bersiap mengimpor...';

  String _selectedMonth = 'September';
  String _selectedYear = '2026';

  final List<String> _monthsList = [
    'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
    'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
  ];

  int _getMonthNumber(String monthName) {
    int index = _monthsList.indexOf(monthName);
    return index != -1 ? index + 1 : DateTime.now().month;
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xlsx', 'xls'],
      withData: true,
    );

    if (result != null && result.files.isNotEmpty) {
      setState(() {
        _selectedFile = result.files.first;
      });
    }
  }

  Future<void> _processAndSave() async {
    if (_selectedFile == null || _selectedFile!.bytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('File Excel belum dipilih atau kosong!')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _importProgress = 0.0;
      _statusMessage = 'Memulai proses...';
    });

    try {
      final monthInt = _getMonthNumber(_selectedMonth);
      final yearInt = int.tryParse(_selectedYear) ?? 2026;

      final startDate = DateTime(yearInt, monthInt, 1);
      final endDate = DateTime(yearInt, monthInt + 1, 0);
      final title = 'Jadwal Patrol 5S $_selectedMonth $_selectedYear';

      // Memanggil service dengan callback onProgress dan bulan pilihan UI
      await _service.importScheduleFromExcel(
        bytes: _selectedFile!.bytes!,
        title: title,
        startDate: startDate,
        endDate: endDate,
        selectedMonth: _selectedMonth, // Bulan disesuaikan dengan pilihan UI
        onProgress: (progress, message) {
          if (mounted) {
            setState(() {
              _importProgress = progress;
              _statusMessage = message;
            });
          }
        },
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Berhasil mengimpor jadwal dari Excel!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      debugPrint('🚨 Error saat Import: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menyimpan jadwal: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: screenWidth > 500 ? 450 : double.infinity,
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Flexible(
                    child: Text(
                      'Import Schedule Patrol',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: _isLoading ? null : () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _buildStepperHeader(),
              const SizedBox(height: 20),
              if (_currentStep == 1) _buildStep1Upload(),
              if (_currentStep == 2) _buildStep2Period(),
              if (_currentStep == 3) _buildStep3Review(),
              const SizedBox(height: 20),
              _buildActionButtons(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepperHeader() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _stepIndicator(1, 'Upload File'),
          _stepDivider(),
          _stepIndicator(2, 'Atur Periode'),
          _stepDivider(),
          _stepIndicator(3, 'Review & Simpan'),
        ],
      ),
    );
  }

  Widget _stepIndicator(int step, String label) {
    final isActive = _currentStep == step;
    return Row(
      children: [
        CircleAvatar(
          radius: 12,
          backgroundColor: isActive ? const Color(0xFF004085) : Colors.grey.shade300,
          child: Text(
            '$step',
            style: TextStyle(
              fontSize: 11,
              color: isActive ? Colors.white : Colors.grey.shade600,
            ),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  Widget _stepDivider() {
    return Container(
      width: 20,
      height: 1,
      color: Colors.grey.shade300,
      margin: const EdgeInsets.symmetric(horizontal: 6),
    );
  }

  Widget _buildStep1Upload() {
    return GestureDetector(
      onTap: _isLoading ? null : _pickFile,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.blue.shade200),
          borderRadius: BorderRadius.circular(8),
          color: Colors.blue.shade50.withValues(alpha: 0.3),
        ),
        child: Column(
          children: [
            const Icon(Icons.cloud_upload_outlined, size: 36, color: Color(0xFF004085)),
            const SizedBox(height: 8),
            Text(
              _selectedFile != null ? _selectedFile!.name : 'Pilih file Excel (.xlsx)',
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep2Period() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Pilih Bulan dan Tahun:', style: TextStyle(fontSize: 12)),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                initialValue: _selectedMonth,
                items: _monthsList.map((m) => DropdownMenuItem(value: m, child: Text(m, style: const TextStyle(fontSize: 12)))).toList(),
                onChanged: _isLoading ? null : (val) => setState(() => _selectedMonth = val!),
                decoration: const InputDecoration(border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8)),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: DropdownButtonFormField<String>(
                initialValue: _selectedYear,
                items: ['2025', '2026', '2027'].map((y) => DropdownMenuItem(value: y, child: Text(y, style: const TextStyle(fontSize: 12)))).toList(),
                onChanged: _isLoading ? null : (val) => setState(() => _selectedYear = val!),
                decoration: const InputDecoration(border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8)),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStep3Review() {
    final percentage = (_importProgress * 100).toInt();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: [
              _reviewRow('File Selected', _selectedFile?.name ?? '-'),
              _reviewRow('Judul Jadwal', 'Jadwal Patrol 5S $_selectedMonth $_selectedYear'),
              _reviewRow('Periode', '$_selectedMonth $_selectedYear'),
            ],
          ),
        ),
        if (_isLoading) ...[
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  _statusMessage,
                  style: const TextStyle(fontSize: 11, color: Color(0xFF004085), fontWeight: FontWeight.w600),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                '$percentage%',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF004085)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: _importProgress,
              minHeight: 8,
              backgroundColor: Colors.grey.shade200,
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF004085)),
            ),
          ),
        ],
      ],
    );
  }

  Widget _reviewRow(String title, String val) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(fontSize: 11, color: Colors.grey)),
          Expanded(
            child: Text(
              val,
              textAlign: TextAlign.right,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        if (_currentStep > 1)
          TextButton(
            onPressed: _isLoading ? null : () => setState(() => _currentStep--),
            child: const Text('Kembali'),
          ),
        const SizedBox(width: 8),
        if (_currentStep < 3)
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2563EB)),
            onPressed: _selectedFile == null ? null : () => setState(() => _currentStep++),
            child: const Text('Lanjut', style: TextStyle(color: Colors.white)),
          )
        else
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF004085)),
            onPressed: _isLoading ? null : _processAndSave,
            child: _isLoading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                  )
                : const Text('Proses & Simpan', style: TextStyle(color: Colors.white)),
          ),
      ],
    );
  }
}