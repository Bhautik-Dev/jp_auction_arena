import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/gradient_button.dart';
import '../../data/models/models.dart';
import '../../data/repositories/repositories.dart';
import '../../core/routing/route_names.dart';
import '../../shared/widgets/app_ui_feedback.dart';

class CreateAuctionScreen extends ConsumerStatefulWidget {
  const CreateAuctionScreen({super.key});

  @override
  ConsumerState<CreateAuctionScreen> createState() => _CreateAuctionScreenState();
}

class _CreateAuctionScreenState extends ConsumerState<CreateAuctionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _venueController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _teamsController = TextEditingController(text: '8');
  final _basePriceController = TextEditingController(text: '10000');
  final _bidIncrementController = TextEditingController(text: '2000');
  final _teamPurseController = TextEditingController(text: '1000000');
  final _countdownController = TextEditingController(text: '30');

  DateTime _startDateTime = DateTime.now().add(const Duration(days: 1));
  final AuctionStatus _status = AuctionStatus.draft;
  AuctionMode _mode = AuctionMode.manual;
  bool _isSaving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _venueController.dispose();
    _descriptionController.dispose();
    _teamsController.dispose();
    _basePriceController.dispose();
    _bidIncrementController.dispose();
    _teamPurseController.dispose();
    _countdownController.dispose();
    super.dispose();
  }

  Future<void> _saveAuction() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final auction = Auction(
        id: 'auc_${DateTime.now().millisecondsSinceEpoch}',
        name: _nameController.text.trim(),
        venue: _venueController.text.trim(),
        description: _descriptionController.text.trim(),
        startDateTime: _startDateTime,
        status: _status,
        numberOfTeams: int.tryParse(_teamsController.text) ?? 8,
        minSquad: 11,
        maxSquad: 15,
        basePriceDefault: double.tryParse(_basePriceController.text) ?? 10000,
        bidIncrement: double.tryParse(_bidIncrementController.text) ?? 2000,
        teamPurse: double.tryParse(_teamPurseController.text) ?? 1000000,
        countdownSeconds: int.tryParse(_countdownController.text) ?? 30,
        mode: _mode,
      );

      await ref.read(auctionRepositoryProvider).save(auction);

      if (!mounted) return;
      setState(() => _isSaving = false);
      AppToast.showSuccess(context, 'Auction "${auction.name}" created!');
      context.go(RouteNames.auctionsPath);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      AppToast.showError(context, 'Failed to create auction: $e');
    }
  }

  Future<void> _pickDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _startDateTime,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.primaryBlue,
              surface: AppColors.card,
            ),
          ),
          child: child!,
        );
      },
    );
    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_startDateTime),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.primaryBlue,
              surface: AppColors.card,
            ),
          ),
          child: child!,
        );
      },
    );
    if (time == null || !mounted) return;

    setState(() {
      _startDateTime = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
  }

  Widget _buildField({
    required String label,
    required TextEditingController controller,
    required String hint,
    required String? Function(String?)? validator,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            maxLines: maxLines,
            validator: validator,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(color: AppColors.textMuted, fontSize: 12),
              filled: true,
              fillColor: AppColors.surfaceLight,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            GlassCard(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.primaryBlue.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(
                          Icons.add_circle_outline_rounded,
                          color: AppColors.primaryBlue,
                          size: 30,
                        ),
                      ),
                      const SizedBox(width: 18),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Create Auction',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Set up a new cricket player auction tournament',
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Auction Details Form
            GlassCard(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Auction Details',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Auction Name
                    _buildField(
                      label: 'Auction Name',
                      controller: _nameController,
                      hint: 'e.g. IPL Mega Auction 2026',
                      validator: (v) => v == null || v.trim().isEmpty
                          ? 'Auction name is required'
                          : null,
                    ),
                    const SizedBox(height: 16),

                    // Venue & Description Row
                    Row(
                      children: [
                        Expanded(
                          child: _buildField(
                            label: 'Venue',
                            controller: _venueController,
                            hint: 'e.g. Wankhede Stadium',
                            validator: (v) => v == null || v.trim().isEmpty
                                ? 'Venue is required'
                                : null,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Start Date & Time',
                                style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceLight,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: AppColors.cardBorder),
                                ),
                                child: ListTile(
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                                  title: Text(
                                    DateFormat('dd MMM yyyy, hh:mm a')
                                        .format(_startDateTime),
                                    style: const TextStyle(color: Colors.white, fontSize: 13),
                                  ),
                                  trailing: const Icon(
                                    Icons.calendar_today_rounded,
                                    color: AppColors.primaryBlue,
                                  ),
                                  onTap: _pickDateTime,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Description
                    _buildField(
                      label: 'Description',
                      controller: _descriptionController,
                      hint: 'Describe your tournament...',
                      maxLines: 3,
                      validator: null,
                    ),
                    const SizedBox(height: 20),

                    // Auction Configuration Row
                    const Text(
                      'Auction Configuration',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 20),

                    Row(
                      children: [
                        // Number of Teams
                        Expanded(
                          child: _buildField(
                            label: 'Number of Teams',
                            controller: _teamsController,
                            hint: '8',
                            keyboardType: TextInputType.number,
                            validator: (v) {
                              final n = int.tryParse(v ?? '');
                              if (n == null || n < 2) return 'Enter valid team count';
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        // Base Price
                        Expanded(
                          child: _buildField(
                            label: 'Base Price (₹)',
                            controller: _basePriceController,
                            hint: '10000',
                            keyboardType: TextInputType.number,
                            validator: (v) {
                              final n = double.tryParse(v ?? '');
                              if (n == null || n < 0) return 'Enter valid price';
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    Row(
                      children: [
                        // Bid Increment
                        Expanded(
                          child: _buildField(
                            label: 'Bid Increment (₹)',
                            controller: _bidIncrementController,
                            hint: '2000',
                            keyboardType: TextInputType.number,
                            validator: (v) {
                              final n = double.tryParse(v ?? '');
                              if (n == null || n <= 0) return 'Enter valid increment';
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        // Team Purse
                        Expanded(
                          child: _buildField(
                            label: 'Team Purse (₹)',
                            controller: _teamPurseController,
                            hint: '1000000',
                            keyboardType: TextInputType.number,
                            validator: (v) {
                              final n = double.tryParse(v ?? '');
                              if (n == null || n < 0) return 'Enter valid purse';
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    Row(
                      children: [
                        // Countdown Seconds
                        Expanded(
                          child: _buildField(
                            label: 'Countdown (seconds)',
                            controller: _countdownController,
                            hint: '30',
                            keyboardType: TextInputType.number,
                            validator: (v) {
                              final n = int.tryParse(v ?? '');
                              if (n == null || n <= 0) return 'Enter valid seconds';
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        // Auction Mode
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Auction Mode',
                                style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceLight,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: AppColors.cardBorder),
                                ),
                                child: DropdownButton<AuctionMode>(
                                  value: _mode,
                                  dropdownColor: AppColors.card,
                      style: const TextStyle(color: Colors.white),
                                  isExpanded: true,
                                  underline: const SizedBox(),
                                  items: AuctionMode.values.map((mode) {
                                    return DropdownMenuItem<AuctionMode>(
                                      value: mode,
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 16),
                                        child: Text(
                                          mode.displayName,
                                          style: const TextStyle(fontSize: 13),
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                  onChanged: (v) => setState(() => _mode = v!),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Save Button
                    SizedBox(
                      width: double.infinity,
                      child: GradientButton(
                        height: 50,
                        onPressed: _isSaving ? null : _saveAuction,
                        icon: _isSaving ? null : Icons.save_rounded,
                        label: _isSaving ? 'Creating...' : 'Create Auction',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
