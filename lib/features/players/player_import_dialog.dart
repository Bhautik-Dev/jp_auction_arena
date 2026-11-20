import 'package:csv/csv.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jp_auction_arena/core/constants/app_colors.dart';
import 'package:jp_auction_arena/core/utils/currency_formatter.dart';
import 'package:jp_auction_arena/core/theme/app_theme.dart';
import 'package:jp_auction_arena/core/widgets/glass_card.dart';
import 'package:jp_auction_arena/core/widgets/gradient_button.dart';
import 'package:jp_auction_arena/data/models/models.dart';
import 'package:jp_auction_arena/data/repositories/repositories.dart';
import 'package:jp_auction_arena/shared/widgets/app_ui_feedback.dart';

/// CSV template columns expected for bulk player import.
const List<String> _csvHeaders = [
  'name',
  'mobile',
  'age',
  'village',
  'category',
  'batting_style',
  'bowling_style',
  'base_price',
  'jersey_number',
  'cric_heroes_url',
  'matches',
  'runs',
  'wickets',
  'batting_average',
  'strike_rate',
  'economy',
];

class PlayerImportDialog extends ConsumerStatefulWidget {
  const PlayerImportDialog({super.key});

  @override
  ConsumerState<PlayerImportDialog> createState() => _PlayerImportDialogState();
}

class _PlayerImportDialogState extends ConsumerState<PlayerImportDialog> {
  bool _isImporting = false;
  String? _previewMessage;
  List<Map<String, dynamic>> _parsedRows = [];

  Future<void> _importCsv(String csvContent) async {
      setState(() {
        _isImporting = true;
        _previewMessage = null;
        _parsedRows = [];
      });

    try {
      final rows = const CsvToListConverter().convert(csvContent);
      if (rows.isEmpty) {
        setState(() {
          _previewMessage = 'No data found in CSV.';
          _isImporting = false;
        });
        return;
      }

      // First row is header
      final header = rows.first.cast<String>();
      final dataRows = rows.skip(1);

      final activeAuction = ref.read(activeAuctionProvider);
      if (activeAuction == null) {
        setState(() {
          _previewMessage = 'No active auction selected.';
          _isImporting = false;
        });
        return;
      }

      final repo = ref.read(playerRepositoryProvider);
      final existing = await repo.getByAuctionId(activeAuction.id);
      final existingMobiles = existing
          .where((p) => p.mobile != null)
          .map((p) => p.mobile!.trim().toLowerCase())
          .toSet();

      int maxNo = existing.fold<int>(0, (m, p) => p.playerNo > m ? p.playerNo : m);
      final List<Player> playersToSave = [];
      int valid = 0;
      int invalid = 0;
      for (final row in dataRows) {
        try {
          final name = _getCell(row, header, 'name')?.trim();
          if (name == null || name.isEmpty) {
            invalid++;
            continue;
          }

          final mobile = _getCell(row, header, 'mobile')?.trim();
          if (mobile != null && mobile.isNotEmpty && existingMobiles.contains(mobile.toLowerCase())) {
            invalid++;
            continue;
          }

          final age = int.tryParse(_getCell(row, header, 'age') ?? '') ?? 20;
          final village = _getCell(row, header, 'village')?.trim() ?? '';
          final category = _getCell(row, header, 'category')?.trim() ?? 'All-Rounder';
          final battingStyle = _getCell(row, header, 'batting_style')?.trim() ?? 'Right Hand Bat';
          final bowlingStyle = _getCell(row, header, 'bowling_style')?.trim() ?? 'Right Arm Medium';
          final basePrice = double.tryParse(_getCell(row, header, 'base_price') ?? '10000') ?? 10000.0;
          final jerseyNo = int.tryParse(_getCell(row, header, 'jersey_number') ?? '') ?? ++maxNo;
          final cricHeroesUrl = _getCell(row, header, 'cric_heroes_url')?.trim();
          final matches = int.tryParse(_getCell(row, header, 'matches') ?? '0') ?? 0;
          final runs = int.tryParse(_getCell(row, header, 'runs') ?? '0') ?? 0;
          final wickets = int.tryParse(_getCell(row, header, 'wickets') ?? '0') ?? 0;
          final battingAverage = double.tryParse(_getCell(row, header, 'batting_average') ?? '0') ?? 0.0;
          final strikeRate = double.tryParse(_getCell(row, header, 'strike_rate') ?? '0') ?? 0.0;
          final economy = double.tryParse(_getCell(row, header, 'economy') ?? '0') ?? 0.0;

          playersToSave.add(Player(
            id: 'p_${DateTime.now().millisecondsSinceEpoch}_${playersToSave.length}',
            auctionId: activeAuction.id,
            playerNo: jerseyNo,
            name: name,
            mobile: mobile?.isEmpty == true ? null : mobile,
            age: age,
            village: village,
            category: category,
            battingStyle: battingStyle,
            bowlingStyle: bowlingStyle,
            cricHeroesUrl: cricHeroesUrl?.isEmpty == true ? null : cricHeroesUrl,
            matches: matches,
            runs: runs,
            wickets: wickets,
            battingAverage: battingAverage,
            strikeRate: strikeRate,
            economy: economy,
            basePrice: basePrice,
          ));
          valid++;
          existingMobiles.add(mobile?.toLowerCase() ?? '');
        } catch (_) {
          invalid++;
        }
      }

      if (playersToSave.isNotEmpty) {
        await repo.saveAll(playersToSave);
      }

      if (mounted) {
        setState(() {
          _parsedRows = playersToSave
              .map((p) => {
                    'name': p.name,
                    'mobile': p.mobile ?? '',
                    'category': p.category,
                    'base_price': formatShort(p.basePrice),
                  })
              .toList();
          _previewMessage =
              'Imported $valid player(s) successfully. $invalid row(s) skipped.';
          _isImporting = false;
        });
        AppToast.showSuccess(
          context,
          'Imported $valid player(s). $invalid row(s) skipped.',
        );
      }
    } catch (e) {
      setState(() {
        _previewMessage = 'Import failed: $e';
        _isImporting = false;
      });
    }
  }

  String? _getCell(List<dynamic> row, List<String> header, String column) {
    final idx = header.indexOf(column);
    if (idx < 0 || idx >= row.length) return null;
    final val = row[idx];
    return val is String ? val : val?.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(20),
      child: GlassCard(
        backgroundColor: AppColors.card,
        width: 640,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primaryBlue.withValues(alpha: 0.2),
                    AppColors.secondaryPurple.withValues(alpha: 0.1),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(AppTheme.cardRadius),
                  topRight: Radius.circular(AppTheme.cardRadius),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.file_upload_rounded,
                    color: AppColors.primaryBlue,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Bulk Import Players',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Import players from CSV. Duplicates by mobile are skipped.',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: AppColors.textSecondary),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // CSV template hint
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceLight.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.cardBorder),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.info_outline_rounded,
                              color: AppColors.info,
                              size: 16,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'CSV Template Columns',
                                style: TextStyle(
                                  color: AppColors.info,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 560),
                          child: Text(
                            _csvHeaders.join(', '),
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 11,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          width: double.infinity,
                          child: GradientButton(
                            onPressed: () => _downloadTemplate(context),
                            icon: Icons.download_rounded,
                            label: 'Download CSV Template',
                            width: double.infinity,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // File picker area
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceLight.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppColors.cardBorder.withValues(alpha: 0.5),
                        style: BorderStyle.solid,
                      ),
                    ),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.cloud_upload_rounded,
                          color: AppColors.textSecondary,
                          size: 40,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Drop CSV file here',
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'or click to select a .csv file',
                          style: TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 11,
                          ),
                        ),
                        const SizedBox(height: 14),
                        SizedBox(
                          width: double.infinity,
                          child: GradientButton(
                            onPressed: _isImporting ? null : () => _pickCsvFile(context),
                            icon: Icons.attach_file_rounded,
                            label: 'Select CSV File',
                            width: double.infinity,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Preview / status
                  if (_previewMessage != null) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: _isImporting
                            ? AppColors.warning.withValues(alpha: 0.1)
                            : AppColors.success.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: _isImporting
                              ? AppColors.warning.withValues(alpha: 0.3)
                              : AppColors.success.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _isImporting ? Icons.hourglass_empty_rounded : Icons.check_circle_rounded,
                            color: _isImporting ? AppColors.warning : AppColors.success,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _previewMessage!,
                              style: TextStyle(
                                color: _isImporting
                                    ? AppColors.warning
                                    : AppColors.success,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],

                  if (_parsedRows.isNotEmpty) ...[
                    const Text(
                      'Preview',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 200,
                      child: ListView.builder(
                        itemCount: _parsedRows.length.clamp(0, 8),
                        itemBuilder: (_, i) {
                          final r = _parsedRows[i];
                          return Container(
                            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                            decoration: BoxDecoration(
                              border: Border(
                                bottom: BorderSide(color: AppColors.cardBorder.withValues(alpha: 0.3)),
                              ),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    r['name'] as String,
                                    style: const TextStyle(color: Colors.white, fontSize: 12),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  r['category'] as String,
                                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  r['base_price'] as String,
                                  style: const TextStyle(color: AppColors.accentPink, fontSize: 11, fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                    if (_parsedRows.length > 8)
                      Text(
                        '...and ${_parsedRows.length - 8} more',
                        style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
                      ),
                  ],

                  const SizedBox(height: 22),

                  Row(
                    children: [
                      GradientButton(
                        onPressed: _isImporting ? null : () => Navigator.of(context).pop(),
                        icon: Icons.cancel_rounded,
                        label: 'Cancel',
                        width: 130,
                        gradient: const LinearGradient(
                          colors: [AppColors.textMuted, AppColors.textMuted],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: GradientButton(
                          onPressed: _isImporting || _parsedRows.isEmpty ? null : () {
                            // Import already done in _importCsv; this is a re-trigger guard
                            Navigator.of(context).pop(true);
                          },
                          icon: _isImporting
                              ? null
                              : Icons.import_contacts_rounded,
                          label: _isImporting ? 'Importing...' : 'Import Players',
                          width: double.infinity,
                          isLoading: _isImporting,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickCsvFile(BuildContext context) async {
    // For web, use file upload via input; for simplicity, show instructions
    // and accept pasted CSV content. On desktop/mobile, use file picker.
    showDialog(
      context: context,
      builder: (ctx) => _CsvPasteDialog(
        onCsvSubmitted: _importCsv,
      ),
    );
  }

  Future<void> _downloadTemplate(BuildContext context) async {
    final csv = const ListToCsvConverter().convert([
      _csvHeaders,
      [
        'Virat Sharma',
        '9876543210',
        '28',
        'Ahmedabad',
        'Batsman',
        'Right Hand Bat',
        'Right Arm Off Spin',
        '200000',
        '18',
        '',
        '45',
        '1800',
        '0',
        '40.00',
        '85.50',
        '0.00',
      ],
      [
        'Rohit Verma',
        '9876543211',
        '30',
        'Mumbai',
        'Bowler',
        'Right Hand Bat',
        'Right Arm Fast',
        '150000',
        '45',
        '',
        '30',
        '200',
        '25',
        '10.00',
        '60.00',
        '4.50',
      ],
    ]);
    if (context.mounted) {
      showDialog(
        context: context,
        builder: (_) => _CsvTemplateDialog(csvContent: csv),
      );
    }
  }
}

/// Dialog to paste CSV content directly (works on web where file picker is limited).
class _CsvPasteDialog extends ConsumerStatefulWidget {
  final ValueChanged<String> onCsvSubmitted;

  const _CsvPasteDialog({required this.onCsvSubmitted});

  @override
  ConsumerState<_CsvPasteDialog> createState() => _CsvPasteDialogState();
}

class _CsvPasteDialogState extends ConsumerState<_CsvPasteDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: GlassCard(
        backgroundColor: AppColors.card,
        width: 520,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  const Icon(Icons.paste_rounded, color: AppColors.primaryBlue, size: 20),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Paste CSV Content',
                      style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: AppColors.textSecondary),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  TextField(
                    controller: _controller,
                    maxLines: 10,
                    style: const TextStyle(color: Colors.white, fontSize: 11, fontFamily: 'monospace'),
                    decoration: InputDecoration(
                      hintText: 'Paste CSV content here (including header row)',
                      hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 11),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.cardBorder),
                      ),
                      filled: true,
                      fillColor: AppColors.surfaceLight.withValues(alpha: 0.3),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      GradientButton(
                        onPressed: () => Navigator.pop(context),
                        icon: Icons.cancel_rounded,
                        label: 'Cancel',
                        width: 120,
                        gradient: const LinearGradient(
                          colors: [AppColors.textMuted, AppColors.textMuted],
                        ),
                      ),
                      const SizedBox(width: 12),
                      GradientButton(
                        onPressed: _controller.text.trim().isEmpty ? null : () {
                          widget.onCsvSubmitted(_controller.text);
                          Navigator.pop(context);
                        },
                        icon: Icons.import_contacts_rounded,
                        label: 'Import',
                        width: double.infinity,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Dialog showing the CSV template content to copy.
class _CsvTemplateDialog extends StatelessWidget {
  final String csvContent;

  const _CsvTemplateDialog({required this.csvContent});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: GlassCard(
        backgroundColor: AppColors.card,
        width: 520,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  const Icon(Icons.description_rounded, color: AppColors.accentPink, size: 20),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'CSV Template',
                      style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: AppColors.textSecondary),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceLight.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: SelectableText(
                      csvContent,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Copy the content above, paste into a .csv file, and import.',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 11),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: GradientButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icons.close_rounded,
                      label: 'Close',
                      width: double.infinity,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
