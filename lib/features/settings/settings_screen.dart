import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_colors.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/gradient_button.dart';
import '../../data/repositories/repositories.dart';
import '../../shared/widgets/feature_placeholder_screen.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  // Profile & Org controllers
  late TextEditingController _profileController;
  late TextEditingController _phoneController;
  late TextEditingController _orgNameController;
  late TextEditingController _orgDescController;

  // Security (Change PIN)
  late TextEditingController _currentPinController;
  late TextEditingController _newPinController;
  late TextEditingController _confirmPinController;
  bool _obscureCurrentPin = true;
  bool _obscureNewPin = true;
  bool _obscureConfirmPin = true;

  // Notifications
  bool _auctionReminders = true;
  bool _soundOn = true;
  bool _voiceOn = true;
  bool _soldAnimation = true;

  // Appearance & Language
  String _language = 'en';
  String _themeAccent = 'blue';
  String _fontSize = 'normal';

  // Data
  bool _autoBackupAfterSale = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final settings = ref.read(settingsRepositoryProvider).getSettings();
    _profileController = TextEditingController(text: settings.profileName);
    _phoneController = TextEditingController(text: settings.phone);
    _orgNameController = TextEditingController(text: settings.orgName);
    _orgDescController = TextEditingController(text: settings.orgDescription);

    _currentPinController = TextEditingController();
    _newPinController = TextEditingController();
    _confirmPinController = TextEditingController();

    _auctionReminders = settings.auctionReminders;
    _soundOn = settings.soundOn;
    _voiceOn = settings.voiceOn;
    _soldAnimation = settings.soldAnimation;

    _language = settings.language;
    _themeAccent = settings.themeAccent;
    _fontSize = settings.fontSize;
    _autoBackupAfterSale = settings.autoBackupAfterSale;
  }

  @override
  void dispose() {
    _profileController.dispose();
    _phoneController.dispose();
    _orgNameController.dispose();
    _orgDescController.dispose();
    _currentPinController.dispose();
    _newPinController.dispose();
    _confirmPinController.dispose();
    super.dispose();
  }

  Future<void> _saveChanges() async {
    setState(() => _isSaving = true);
    final repo = ref.read(settingsRepositoryProvider);
    final currentSettings = repo.getSettings();

    // Check if user is trying to change PIN
    String updatedPin = currentSettings.pin;
    final newPinText = _newPinController.text.trim();
    if (newPinText.isNotEmpty) {
      final currentPinInput = _currentPinController.text.trim();
      if (currentSettings.pin.isNotEmpty && currentPinInput != currentSettings.pin) {
        setState(() => _isSaving = false);
        _showToast('Current PIN is incorrect.', isError: true);
        return;
      }
      if (newPinText != _confirmPinController.text.trim()) {
        setState(() => _isSaving = false);
        _showToast('New PIN and confirmation PIN do not match.', isError: true);
        return;
      }
      if (newPinText.length < 4) {
        setState(() => _isSaving = false);
        _showToast('PIN must be at least 4 digits.', isError: true);
        return;
      }
      updatedPin = newPinText;
      _currentPinController.clear();
      _newPinController.clear();
      _confirmPinController.clear();
    }

    final updated = currentSettings.copyWith(
      profileName: _profileController.text.trim(),
      phone: _phoneController.text.trim(),
      orgName: _orgNameController.text.trim(),
      orgDescription: _orgDescController.text.trim(),
      pin: updatedPin,
      auctionReminders: _auctionReminders,
      soundOn: _soundOn,
      voiceOn: _voiceOn,
      soldAnimation: _soldAnimation,
      language: _language,
      themeAccent: _themeAccent,
      fontSize: _fontSize,
      autoBackupAfterSale: _autoBackupAfterSale,
    );

    await repo.saveSettings(updated);
    setState(() => _isSaving = false);

    _showToast('Settings saved successfully!');
  }

  void _showToast(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: isError ? AppColors.error : AppColors.card,
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline_rounded : Icons.check_circle_rounded,
              color: isError ? Colors.white : AppColors.success,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // ==========================================
  // DATA ACTIONS: Backup, Restore, Clear
  // ==========================================
  Future<void> _handleDownloadBackup() async {
    try {
      final jsonContent = await ref.read(dataBackupServiceProvider).createBackupJson();
      // On web/desktop/mobile, copy to clipboard without hanging tests
      Clipboard.setData(ClipboardData(text: jsonContent)).catchError((_) {});

      if (!mounted) return;
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: AppColors.card,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          title: const Row(
            children: [
              Icon(Icons.cloud_download_rounded, color: AppColors.primaryBlue),
              SizedBox(width: 10),
              Text('Backup Generated', style: TextStyle(color: Colors.white, fontSize: 18)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Complete database backup (auctions, teams, players, bids, settings) has been created and copied to your clipboard.\n\nSave or paste this text into a file to transfer data between laptop and phone.',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: Text(
                  'Size: ${(jsonContent.length / 1024).toStringAsFixed(1)} KB (JSON ready)',
                  style: const TextStyle(color: AppColors.accentPink, fontWeight: FontWeight.bold, fontSize: 12),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Close', style: TextStyle(color: AppColors.textSecondary)),
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryBlue,
                foregroundColor: Colors.white,
              ),
              icon: const Icon(Icons.copy_rounded, size: 16),
              label: const Text('Copy Again'),
              onPressed: () {
                Clipboard.setData(ClipboardData(text: jsonContent));
                Navigator.pop(ctx);
                _showToast('Backup JSON re-copied to clipboard!');
              },
            ),
          ],
        ),
      );
    } catch (e, stack) {
      debugPrint('Backup error: $e\n$stack');
      _showToast('Failed to create backup: $e', isError: true);
    }
  }

  Future<void> _handleRestoreFromJson() async {
    final controller = TextEditingController();
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Row(
          children: [
            Icon(Icons.settings_backup_restore_rounded, color: AppColors.accentPink),
            SizedBox(width: 10),
            Text('Restore from JSON', style: TextStyle(color: Colors.white, fontSize: 18)),
          ],
        ),
        content: SizedBox(
          width: 480,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Paste your exported backup JSON below. Existing auctions, teams, players, and bids will be replaced with the imported data.',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: controller,
                maxLines: 8,
                style: const TextStyle(fontFamily: 'monospace', fontSize: 12, color: Colors.white),
                decoration: InputDecoration(
                  hintText: '{\n  "version": "1.0",\n  "auctions": [...]\n}',
                  fillColor: AppColors.surfaceLight,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  icon: const Icon(Icons.paste_rounded, size: 14),
                  label: const Text('Paste from Clipboard', style: TextStyle(fontSize: 12)),
                  onPressed: () async {
                    final data = await Clipboard.getData('text/plain');
                    if (data?.text != null) {
                      controller.text = data!.text!;
                    }
                  },
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.accentPink, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Restore Data'),
          ),
        ],
      ),
    );

    if (result == true && controller.text.trim().isNotEmpty) {
      try {
        final counts = await ref.read(dataBackupServiceProvider).restoreFromJson(controller.text.trim());
        ref.invalidate(auctionsListProvider);
        ref.invalidate(currentAuctionPlayersProvider);
        ref.invalidate(currentAuctionTeamsProvider);
        ref.invalidate(currentAuctionBidsProvider);
        ref.invalidate(appSettingsProvider);

        _showToast(
          'Restored: ${counts['auctions']} auctions, ${counts['teams']} teams, ${counts['players']} players, ${counts['bids']} bids.',
        );
      } catch (e) {
        _showToast('Restore failed: $e', isError: true);
      }
    }
  }

  Future<void> _handleClearAllData() async {
    // Confirmation 1: Alert Dialog
    final firstConfirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: AppColors.error),
            SizedBox(width: 10),
            Text('Clear All Data?', style: TextStyle(color: Colors.white, fontSize: 18)),
          ],
        ),
        content: const Text(
          'This will permanently delete all auctions, teams, players, and bid history stored on this device.\n\nAre you sure you want to proceed?',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Continue to Final Confirmation'),
          ),
        ],
      ),
    );

    if (firstConfirm != true) return;

    // Confirmation 2: Explicit Type "DELETE" double-confirmation
    if (!mounted) return;
    final confirmController = TextEditingController();
    final secondConfirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          final isMatch = confirmController.text.trim().toUpperCase() == 'CLEAR ALL';
          return AlertDialog(
            backgroundColor: AppColors.card,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            title: const Row(
              children: [
                Icon(Icons.delete_forever_rounded, color: AppColors.error),
                SizedBox(width: 10),
                Text('Double Confirmation', style: TextStyle(color: Colors.white, fontSize: 18)),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'To finalize total reset, type "CLEAR ALL" below:',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: confirmController,
                  autofocus: true,
                  onChanged: (_) => setDialogState(() {}),
                  decoration: const InputDecoration(
                    hintText: 'CLEAR ALL',
                    counterText: '',
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Abort', style: TextStyle(color: AppColors.textSecondary)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: isMatch ? AppColors.error : AppColors.surfaceLight,
                  foregroundColor: Colors.white,
                ),
                onPressed: isMatch ? () => Navigator.pop(ctx, true) : null,
                child: const Text('Permanently Erase All Data'),
              ),
            ],
          );
        },
      ),
    );

    if (secondConfirm == true) {
      await ref.read(dataBackupServiceProvider).clearAllData();
      ref.invalidate(auctionsListProvider);
      ref.invalidate(currentAuctionPlayersProvider);
      ref.invalidate(currentAuctionTeamsProvider);
      ref.invalidate(currentAuctionBidsProvider);
      _showToast('All local auction and player data has been cleared.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return FeaturePlaceholderScreen(
      title: 'Application Settings',
      description: 'Personal profile, security PIN, notifications, branding & local data backup',
      icon: Icons.settings_rounded,
      actionButton: GradientButton(
        onPressed: _isSaving ? null : _saveChanges,
        icon: Icons.save_rounded,
        label: _isSaving ? 'Saving...' : 'Save Changes',
      ),
      children: [
        _buildProfileAndOrgSection(),
        const SizedBox(height: 20),
        _buildSecuritySection(),
        const SizedBox(height: 20),
        _buildNotificationsSection(),
        const SizedBox(height: 20),
        _buildLanguageAndThemeSection(),
        const SizedBox(height: 20),
        _buildDataManagementSection(),
        const SizedBox(height: 24),
        Align(
          alignment: Alignment.centerRight,
          child: GradientButton(
            onPressed: _isSaving ? null : _saveChanges,
            icon: Icons.save_rounded,
            label: _isSaving ? 'Saving...' : 'Save Changes',
          ),
        ),
      ],
    );
  }

  // ==========================================
  // SECTION 1: Profile & Organization
  // ==========================================
  Widget _buildProfileAndOrgSection() {
    return GlassCard(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isCompact = constraints.maxWidth < 580;

          Widget wrapRow(Widget first, Widget second) {
            if (isCompact) {
              return Column(
                children: [
                  first,
                  const SizedBox(height: 14),
                  second,
                ],
              );
            }
            return Row(
              children: [
                Expanded(child: first),
                const SizedBox(width: 16),
                Expanded(child: second),
              ],
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 8,
                children: [
                  Icon(Icons.person_outline_rounded, color: AppColors.primaryBlue, size: 20),
                  Text(
                    'Profile & Organization',
                    style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              const Text(
                'Your identity and tournament organization branding',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
              ),
              const SizedBox(height: 18),
              wrapRow(
                TextField(
                  controller: _profileController,
                  decoration: const InputDecoration(
                    labelText: 'Auctioneer / Admin Name',
                    prefixIcon: Icon(Icons.badge_outlined, color: AppColors.textSecondary, size: 18),
                  ),
                ),
                TextField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Contact Phone Number',
                    prefixIcon: Icon(Icons.phone_outlined, color: AppColors.textSecondary, size: 18),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              wrapRow(
                TextField(
                  controller: _orgNameController,
                  decoration: const InputDecoration(
                    labelText: 'Organization / League Name',
                    prefixIcon: Icon(Icons.business_outlined, color: AppColors.textSecondary, size: 18),
                  ),
                ),
                TextField(
                  controller: _orgDescController,
                  decoration: const InputDecoration(
                    labelText: 'Organization Tagline / Description',
                    prefixIcon: Icon(Icons.description_outlined, color: AppColors.textSecondary, size: 18),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // ==========================================
  // SECTION 2: Security (Change PIN)
  // ==========================================
  Widget _buildSecuritySection() {
    return GlassCard(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isCompact = constraints.maxWidth < 620;

          final currentField = TextField(
            controller: _currentPinController,
            obscureText: _obscureCurrentPin,
            maxLength: 6,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Current PIN',
              counterText: '',
              prefixIcon: const Icon(Icons.key_outlined, color: AppColors.textSecondary, size: 18),
              suffixIcon: IconButton(
                icon: Icon(_obscureCurrentPin ? Icons.visibility_off : Icons.visibility, size: 18, color: AppColors.textMuted),
                onPressed: () => setState(() => _obscureCurrentPin = !_obscureCurrentPin),
              ),
            ),
          );

          final newField = TextField(
            controller: _newPinController,
            obscureText: _obscureNewPin,
            maxLength: 6,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'New PIN (4-6 digits)',
              counterText: '',
              prefixIcon: const Icon(Icons.password_rounded, color: AppColors.textSecondary, size: 18),
              suffixIcon: IconButton(
                icon: Icon(_obscureNewPin ? Icons.visibility_off : Icons.visibility, size: 18, color: AppColors.textMuted),
                onPressed: () => setState(() => _obscureNewPin = !_obscureNewPin),
              ),
            ),
          );

          final confirmField = TextField(
            controller: _confirmPinController,
            obscureText: _obscureConfirmPin,
            maxLength: 6,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Confirm New PIN',
              counterText: '',
              prefixIcon: const Icon(Icons.check_circle_outline, color: AppColors.textSecondary, size: 18),
              suffixIcon: IconButton(
                icon: Icon(_obscureConfirmPin ? Icons.visibility_off : Icons.visibility, size: 18, color: AppColors.textMuted),
                onPressed: () => setState(() => _obscureConfirmPin = !_obscureConfirmPin),
              ),
            ),
          );

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 8,
                children: [
                  Icon(Icons.lock_outline_rounded, color: AppColors.accentPink, size: 20),
                  Text(
                    'Security & PIN Access',
                    style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              const Text(
                'Change master auctioneer PIN for administrative actions and live hammer overrides',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
              ),
              const SizedBox(height: 18),
              if (isCompact) ...[
                currentField,
                const SizedBox(height: 12),
                newField,
                const SizedBox(height: 12),
                confirmField,
              ] else
                Row(
                  children: [
                    Expanded(child: currentField),
                    const SizedBox(width: 14),
                    Expanded(child: newField),
                    const SizedBox(width: 14),
                    Expanded(child: confirmField),
                  ],
                ),
            ],
          );
        },
      ),
    );
  }

  // ==========================================
  // SECTION 3: Notifications & Audio
  // ==========================================
  Widget _buildNotificationsSection() {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            children: [
              Icon(Icons.notifications_active_outlined, color: AppColors.gold, size: 20),
              Text(
                'Notifications & Live Auction Audio',
                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'Audible cues, gavel effects, speech synthesis, and screen animations',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
          ),
          const SizedBox(height: 12),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            secondary: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: AppColors.primaryBlue.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
              child: const Icon(Icons.event_available_rounded, color: AppColors.primaryBlue, size: 20),
            ),
            title: const Text('Auction Reminders', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
            subtitle: const Text('Display alerts prior to scheduled auction commencement', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
            value: _auctionReminders,
            activeThumbColor: AppColors.primaryBlue,
            activeTrackColor: AppColors.primaryBlue.withValues(alpha: 0.5),
            onChanged: (v) => setState(() => _auctionReminders = v),
          ),
          const Divider(),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            secondary: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: AppColors.accentPink.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
              child: const Icon(Icons.volume_up_rounded, color: AppColors.accentPink, size: 20),
            ),
            title: const Text('Bid & Gavel Sound Effects', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
            subtitle: const Text('Chimes on incoming bids, countdown warning beeps, and hammer hit sound', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
            value: _soundOn,
            activeThumbColor: AppColors.accentPink,
            activeTrackColor: AppColors.accentPink.withValues(alpha: 0.5),
            onChanged: (v) => setState(() => _soundOn = v),
          ),
          const Divider(),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            secondary: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: AppColors.secondaryPurple.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
              child: const Icon(Icons.record_voice_over_rounded, color: AppColors.secondaryPurple, size: 20),
            ),
            title: const Text('Voice Announcer', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
            subtitle: const Text('Text-to-speech engine speaks out team bids and player sold prices', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
            value: _voiceOn,
            activeThumbColor: AppColors.secondaryPurple,
            activeTrackColor: AppColors.secondaryPurple.withValues(alpha: 0.5),
            onChanged: (v) => setState(() => _voiceOn = v),
          ),
          const Divider(),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            secondary: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: AppColors.success.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
              child: const Icon(Icons.celebration_rounded, color: AppColors.success, size: 20),
            ),
            title: const Text('SOLD Celebration Animation', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
            subtitle: const Text('Show full-screen confetti & stamp celebration when a player is hammered SOLD', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
            value: _soldAnimation,
            activeThumbColor: AppColors.success,
            activeTrackColor: AppColors.success.withValues(alpha: 0.5),
            onChanged: (v) => setState(() => _soldAnimation = v),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // SECTION 4: Language, Theme Accent & Font
  // ==========================================
  Widget _buildLanguageAndThemeSection() {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            children: [
              Icon(Icons.palette_outlined, color: AppColors.info, size: 20),
              Text(
                'Appearance, Language & Display',
                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'Regional language selection, gradient accent presets, and font scale',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
          ),
          const SizedBox(height: 18),
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth > 800;
              final colWidth = isWide ? (constraints.maxWidth - 32) / 3 : constraints.maxWidth;

              return Wrap(
                spacing: 16,
                runSpacing: 16,
                children: [
                  // Language Chooser
                  SizedBox(
                    width: colWidth,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Language', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceLight,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppColors.cardBorder),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              isExpanded: true,
                              dropdownColor: AppColors.card,
                              value: _language,
                              items: const [
                                DropdownMenuItem(value: 'en', child: Text('English (Default)', style: TextStyle(color: Colors.white))),
                                DropdownMenuItem(value: 'gu', child: Text('ગુજરાતી (Gujarati)', style: TextStyle(color: Colors.white))),
                                DropdownMenuItem(value: 'hi', child: Text('हिन्दी (Hindi)', style: TextStyle(color: Colors.white))),
                              ],
                              onChanged: (v) {
                                if (v != null) setState(() => _language = v);
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Theme Accent Chooser
                  SizedBox(
                    width: colWidth,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Theme Accent Presets', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            _buildThemePresetOption('blue', 'Electric Blue', const [AppColors.primaryBlue, Color(0xFF1D4ED8)]),
                            const SizedBox(width: 8),
                            _buildThemePresetOption('purple', 'Deep Purple', const [AppColors.secondaryPurple, Color(0xFF6D28D9)]),
                            const SizedBox(width: 8),
                            _buildThemePresetOption('pink', 'Neon Pink', const [AppColors.accentPink, Color(0xFFBE185D)]),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Font Size
                  SizedBox(
                    width: colWidth,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Font Size / Scaling', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceLight,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppColors.cardBorder),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              isExpanded: true,
                              dropdownColor: AppColors.card,
                              value: _fontSize,
                              items: const [
                                DropdownMenuItem(value: 'compact', child: Text('Compact (Dense displays)', style: TextStyle(color: Colors.white))),
                                DropdownMenuItem(value: 'normal', child: Text('Normal (Recommended)', style: TextStyle(color: Colors.white))),
                                DropdownMenuItem(value: 'large', child: Text('Large (Projector / TV)', style: TextStyle(color: Colors.white))),
                              ],
                              onChanged: (v) {
                                if (v != null) setState(() => _fontSize = v);
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildThemePresetOption(String key, String label, List<Color> gradientColors) {
    final isSelected = _themeAccent == key;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _themeAccent = key),
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? gradientColors.first : AppColors.cardBorder,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: gradientColors),
                  shape: BoxShape.circle,
                  boxShadow: isSelected
                      ? [BoxShadow(color: gradientColors.first.withValues(alpha: 0.5), blurRadius: 8, spreadRadius: 1)]
                      : null,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : AppColors.textSecondary,
                  fontSize: 10,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================
  // SECTION 5: Data Backup, Restore & Reset
  // ==========================================
  Widget _buildDataManagementSection() {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 4,
            children: [
              const Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 8,
                children: [
                  Icon(Icons.storage_rounded, color: AppColors.success, size: 20),
                  Text(
                    'Data Management & Offline Sync',
                    style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text('Offline Local Database', style: TextStyle(color: AppColors.success, fontSize: 11, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'Since JP AUCTION ARENA operates completely serverless and offline, backup and restore via JSON is the only way to move auction data between phone and laptop.',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
          ),
          const SizedBox(height: 18),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            secondary: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: AppColors.gold.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
              child: const Icon(Icons.auto_mode_rounded, color: AppColors.gold, size: 20),
            ),
            title: const Text('Auto-backup after every sale', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
            subtitle: const Text('Automatically snapshot database state whenever a player is marked SOLD', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
            value: _autoBackupAfterSale,
            activeThumbColor: AppColors.gold,
            activeTrackColor: AppColors.gold.withValues(alpha: 0.5),
            onChanged: (v) => setState(() => _autoBackupAfterSale = v),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryBlue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                icon: const Icon(Icons.download_rounded, size: 18),
                label: const Text('Backup (Download JSON)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                onPressed: _handleDownloadBackup,
              ),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: AppColors.cardBorder),
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                icon: const Icon(Icons.settings_backup_restore_rounded, size: 18, color: AppColors.accentPink),
                label: const Text('Restore from JSON', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                onPressed: _handleRestoreFromJson,
              ),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.error,
                  side: BorderSide(color: AppColors.error.withValues(alpha: 0.5)),
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                icon: const Icon(Icons.delete_forever_rounded, size: 18),
                label: const Text('Clear All Data', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                onPressed: _handleClearAllData,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
