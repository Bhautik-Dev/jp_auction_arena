import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/gradient_button.dart';
import '../../data/models/models.dart';
import '../../data/repositories/repositories.dart';
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

  String _category = 'All-Rounder';
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select or create an auction first.')),
      );
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    final player = Player(
      id: 'pl_${DateTime.now().millisecondsSinceEpoch}',
      auctionId: activeAuction.id,
      playerNo: int.tryParse(_playerNoController.text.trim()) ?? 1,
      name: _nameController.text.trim(),
      age: int.tryParse(_ageController.text.trim()) ?? 20,
      village: _villageController.text.trim(),
      category: _category,
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Player "${player.name}" registered successfully!'),
          backgroundColor: AppColors.success,
        ),
      );
      _nameController.clear();
      _villageController.clear();
      final nextNo = (int.tryParse(_playerNoController.text) ?? 1) + 1;
      _playerNoController.text = nextNo.toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeAuction = ref.watch(activeAuctionProvider);

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
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Cricket Player Bio & Registration',
                  style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    SizedBox(
                      width: 120,
                      child: TextFormField(
                        controller: _playerNoController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Lot No.'),
                        validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Player Full Name',
                          prefixIcon: Icon(Icons.person_outline),
                        ),
                        validator: (v) => v == null || v.trim().isEmpty ? 'Enter player name' : null,
                      ),
                    ),
                    const SizedBox(width: 16),
                    SizedBox(
                      width: 120,
                      child: TextFormField(
                        controller: _ageController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Age'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _villageController,
                        decoration: const InputDecoration(
                          labelText: 'Village / Town / Club',
                          prefixIcon: Icon(Icons.location_city_outlined),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: _category,
                        decoration: const InputDecoration(labelText: 'Category'),
                        items: const [
                          DropdownMenuItem(value: 'Batsman', child: Text('Batsman')),
                          DropdownMenuItem(value: 'Bowler', child: Text('Bowler')),
                          DropdownMenuItem(value: 'All-Rounder', child: Text('All-Rounder')),
                          DropdownMenuItem(value: 'Wicket-Keeper', child: Text('Wicket-Keeper')),
                        ],
                        onChanged: (val) {
                          if (val != null) setState(() => _category = val);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
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
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: DropdownButtonFormField<String>(
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
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        controller: _basePriceController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Base Price (₹)',
                          prefixIcon: Icon(Icons.currency_rupee_rounded),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _matchesController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Matches'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _runsController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Total Runs'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _wicketsController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Total Wickets'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _strikeRateController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Strike Rate'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
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
                  alignment: Alignment.centerRight,
                  child: GradientButton(
                    onPressed: _handleSave,
                    icon: Icons.person_add_rounded,
                    label: 'Register Player to Pool',
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
