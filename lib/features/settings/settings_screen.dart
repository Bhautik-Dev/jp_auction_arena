import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/gradient_button.dart';
import '../../data/models/models.dart';
import '../../data/repositories/repositories.dart';
import '../../shared/widgets/feature_placeholder_screen.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  late TextEditingController _profileController;
  late TextEditingController _orgController;
  late TextEditingController _phoneController;
  late TextEditingController _pinController;
  bool _soundOn = true;
  bool _voiceOn = true;
  String _language = 'en';
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      final settings = ref.read(settingsRepositoryProvider).getSettings();
      _profileController = TextEditingController(text: settings.profileName);
      _orgController = TextEditingController(text: settings.orgName);
      _phoneController = TextEditingController(text: settings.phone);
      _pinController = TextEditingController(text: settings.pin);
      _soundOn = settings.soundOn;
      _voiceOn = settings.voiceOn;
      _language = settings.language;
      _initialized = true;
    }
  }

  @override
  void dispose() {
    _profileController.dispose();
    _orgController.dispose();
    _phoneController.dispose();
    _pinController.dispose();
    super.dispose();
  }

  Future<void> _saveSettings() async {
    final updated = AppSettings(
      profileName: _profileController.text.trim(),
      orgName: _orgController.text.trim(),
      phone: _phoneController.text.trim(),
      pin: _pinController.text.trim(),
      language: _language,
      soundOn: _soundOn,
      voiceOn: _voiceOn,
    );

    await ref.read(settingsRepositoryProvider).saveSettings(updated);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Settings saved locally!'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return FeaturePlaceholderScreen(
      title: 'Application Settings',
      description: 'Audio, sound effects, security PIN, and organization branding',
      icon: Icons.settings_rounded,
      children: [
        GlassCard(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Organization & Profile',
                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _profileController,
                      decoration: const InputDecoration(labelText: 'Admin / Auctioneer Name'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextField(
                      controller: _orgController,
                      decoration: const InputDecoration(labelText: 'Club / Association Name'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _phoneController,
                      decoration: const InputDecoration(labelText: 'Contact Phone'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextField(
                      controller: _pinController,
                      obscureText: true,
                      maxLength: 6,
                      decoration: const InputDecoration(labelText: 'Security PIN', counterText: ''),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const Text(
                'Audio & Sounds',
                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Gavel Sound Effects & Timer Bells', style: TextStyle(color: Colors.white)),
                subtitle: const Text('Play sound on countdown and sold gavel strike', style: TextStyle(color: AppColors.textSecondary)),
                value: _soundOn,
                activeThumbColor: AppColors.accentPink,
                activeTrackColor: AppColors.accentPink.withValues(alpha: 0.5),
                onChanged: (v) => setState(() => _soundOn = v),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Voice Announcements', style: TextStyle(color: Colors.white)),
                subtitle: const Text('Text-to-speech announces new bids and sold players', style: TextStyle(color: AppColors.textSecondary)),
                value: _voiceOn,
                activeThumbColor: AppColors.primaryBlue,
                activeTrackColor: AppColors.primaryBlue.withValues(alpha: 0.5),
                onChanged: (v) => setState(() => _voiceOn = v),
              ),
              const SizedBox(height: 24),
              Align(
                alignment: Alignment.centerRight,
                child: GradientButton(
                  onPressed: _saveSettings,
                  icon: Icons.save_rounded,
                  label: 'Save Settings',
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
