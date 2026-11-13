import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/gradient_button.dart';
import '../../data/models/models.dart';
import '../../data/repositories/repositories.dart';
import '../../shared/widgets/app_ui_feedback.dart';
import '../../shared/widgets/feature_placeholder_screen.dart';

class RegistrationScreen extends ConsumerStatefulWidget {
  const RegistrationScreen({super.key});

  @override
  ConsumerState<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends ConsumerState<RegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _playerNoController = TextEditingController(text: '1');
  final _ageController = TextEditingController(text: '22');
  final _villageController = TextEditingController();
  final _basePriceController = TextEditingController(text: '10000');
  final _runsController = TextEditingController(text: '0');
  final _wicketsController = TextEditingController(text: '0');
  final _matchesController = TextEditingController(text: '0');
  final _strikeRateController = TextEditingController(text: '0.0');

  String? _category;
  String _battingStyle = 'Right Hand Bat';
  String _bowlingStyle = 'Right Arm Medium';
  bool _isIcon = false;

  @override
  void dispose() {
    _nameController.dispose();
    _playerNoController.dispose();
    _ageController.dispose();
    _villageController.dispose();
    _basePriceController.dispose();
    _runsController.dispose();
    _wicketsController.dispose();
    _matchesController.dispose();
    _strikeRateController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    final activeAuction = ref.read(activeAuctionProvider);
    if (activeAuction == null) {
      AppToast.showError(context, 'Please select or create an auction first.');
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    final inputPlayerNo = int.tryParse(_playerNoController.text.trim()) ?? 1;

    // Guard against duplicate player number in the same auction
    final existingPlayers = ref.read(playerRepositoryProvider).getByAuctionId(activeAuction.id);
    final isDuplicate = existingPlayers.any((p) => p.playerNo == inputPlayerNo);
    if (isDuplicate) {
      AppToast.showError(context, 'Player lot number #$inputPlayerNo is already assigned in this auction. Please choose a unique number.');
      return;
    }

    final categories = activeAuction.categories.isNotEmpty
        ? activeAuction.categories
        : const ['Batsman', 'Bowler', 'All-Rounder', 'Wicket-Keeper'];

    final player = Player(
      id: 'pl_${DateTime.now().millisecondsSinceEpoch}',
      auctionId: activeAuction.id,
      playerNo: inputPlayerNo,
      name: _nameController.text.trim(),
      age: int.tryParse(_ageController.text.trim()) ?? 20,
      village: _villageController.text.trim(),
      category: _category ?? (categories.isNotEmpty ? categories.first : 'All-Rounder'),
      battingStyle: _battingStyle,
      bowlingStyle: _bowlingStyle,
      matches: int.tryParse(_matchesController.text.trim()) ?? 0,
      runs: int.tryParse(_runsController.text.trim()) ?? 0,
      wickets: int.tryParse(_wicketsController.text.trim()) ?? 0,
      strikeRate: double.tryParse(_strikeRateController.text.trim()) ?? 0.0,
      basePrice: double.tryParse(_basePriceController.text.trim()) ?? activeAuction.basePriceDefault,
      isIcon: _isIcon,
    );

    await ref.read(playerRepositoryProvider).save(player);

    if (mounted) {
      AppToast.showSuccess(context, 'Player "${player.name}" (#${player.playerNo}) registered successfully!');
      _nameController.clear();
      _villageController.clear();
      // Auto-calculate the next available unique player number
      final nextNumber = existingPlayers.fold<int>(inputPlayerNo, (max, p) => p.playerNo > max ? p.playerNo : max) + 1;
      _playerNoController.text = nextNumber.toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeAuction = ref.watch(activeAuctionProvider);

    final availableCategories = activeAuction?.categories.isNotEmpty == true
        ? activeAuction!.categories
        : const ['Batsman', 'Bowler', 'All-Rounder', 'Wicket-Keeper'];

    if (_category == null || !availableCategories.contains(_category)) {
      _category = availableCategories.first;
    }

    return FeaturePlaceholderScreen(
      title: 'Player Registration Desk',
      description: activeAuction != null
          ? 'Enrolling players for "${activeAuction.name}"'
          : 'Create an auction to begin registration',
      icon: Icons.app_registration_rounded,
      children: [
        Form(
          key: _formKey,
          child: GlassCard(
            padding: const EdgeInsets.all(20),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isCompact = constraints.maxWidth < 600;

                Widget wrapResponsiveRow(List<Widget> children, {double spacing = 12}) {
                  if (isCompact) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisSize: MainAxisSize.min,
                      children: children
                          .map((w) => Padding(
                                padding: EdgeInsets.only(bottom: spacing),
                                child: w,
                              ))
                          .toList(),
                    );
                  }
                  return Row(
                    children: children
                        .map((w) => Expanded(
                              child: Padding(
                                padding: EdgeInsets.symmetric(horizontal: spacing / 2),
                                child: w,
                              ),
                            ))
                        .toList(),
                  );
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Cricket Player Bio & Registration',
                      style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 18),
                    wrapResponsiveRow([
                      TextFormField(
                        controller: _playerNoController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Lot No.'),
                        validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                      ),
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Player Full Name',
                          prefixIcon: Icon(Icons.person_outline),
                        ),
                        validator: (v) => v == null || v.trim().isEmpty ? 'Enter player name' : null,
                      ),
                      TextFormField(
                        controller: _ageController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Age'),
                      ),
                    ]),
                    const SizedBox(height: 12),
                    wrapResponsiveRow([
                      TextFormField(
                        controller: _villageController,
                        decoration: const InputDecoration(
                          labelText: 'Village / Town / Club',
                          prefixIcon: Icon(Icons.location_city_outlined),
                        ),
                      ),
                      DropdownButtonFormField<String>(
                        isExpanded: true,
                        initialValue: _category,
                        decoration: const InputDecoration(labelText: 'Category'),
                        items: availableCategories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _category = val);
                        },
                      ),
                    ]),
                    const SizedBox(height: 12),
                    wrapResponsiveRow([
                      DropdownButtonFormField<String>(
                        isExpanded: true,
                        initialValue: _battingStyle,
                        decoration: const InputDecoration(labelText: 'Batting Style'),
                        items: const [
                          DropdownMenuItem(value: 'Right Hand Bat', child: Text('Right Hand Bat')),
                          DropdownMenuItem(value: 'Left Hand Bat', child: Text('Left Hand Bat')),
                        ],
                        onChanged: (val) {
                          if (val != null) setState(() => _battingStyle = val);
                        },
                      ),
                      DropdownButtonFormField<String>(
                        isExpanded: true,
                        initialValue: _bowlingStyle,
                        decoration: const InputDecoration(labelText: 'Bowling Style'),
                        items: const [
                          DropdownMenuItem(value: 'Right Arm Medium', child: Text('Right Arm Medium')),
                          DropdownMenuItem(value: 'Right Arm Fast', child: Text('Right Arm Fast')),
                          DropdownMenuItem(value: 'Right Arm Spin', child: Text('Right Arm Spin')),
                          DropdownMenuItem(value: 'Left Arm Spin', child: Text('Left Arm Spin')),
                          DropdownMenuItem(value: 'Left Arm Fast', child: Text('Left Arm Fast')),
                        ],
                        onChanged: (val) {
                          if (val != null) setState(() => _bowlingStyle = val);
                        },
                      ),
                      TextFormField(
                        controller: _basePriceController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Base Price (₹)',
                          prefixIcon: Icon(Icons.currency_rupee_rounded),
                        ),
                      ),
                    ]),
                    const SizedBox(height: 12),
                    wrapResponsiveRow([
                      TextFormField(
                        controller: _matchesController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Matches'),
                      ),
                      TextFormField(
                        controller: _runsController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Total Runs'),
                      ),
                      TextFormField(
                        controller: _wicketsController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Total Wickets'),
                      ),
                      TextFormField(
                        controller: _strikeRateController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Strike Rate'),
                      ),
                    ]),
                    const SizedBox(height: 14),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Icon Player (Marquee / Star)', style: TextStyle(color: Colors.white)),
                      subtitle: const Text('Highlighted during live lot generation', style: TextStyle(color: AppColors.textSecondary)),
                      value: _isIcon,
                      activeTrackColor: AppColors.accentPink.withValues(alpha: 0.5),
                      activeThumbColor: AppColors.accentPink,
                      onChanged: (val) => setState(() => _isIcon = val),
                    ),
                    const SizedBox(height: 20),
                    Align(
                      alignment: isCompact ? Alignment.center : Alignment.centerRight,
                      child: GradientButton(
                        width: isCompact ? double.infinity : null,
                        onPressed: _handleSave,
                        icon: Icons.person_add_rounded,
                        label: 'Register Player to Pool',
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}
