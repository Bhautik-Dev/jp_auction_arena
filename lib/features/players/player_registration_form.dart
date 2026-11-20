import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:jp_auction_arena/core/constants/app_colors.dart';
import 'package:jp_auction_arena/core/theme/app_theme.dart';
import 'package:jp_auction_arena/core/widgets/glass_card.dart';
import 'package:jp_auction_arena/core/widgets/gradient_button.dart';
import 'package:jp_auction_arena/data/models/models.dart';
import 'package:jp_auction_arena/data/repositories/repositories.dart';
import 'package:jp_auction_arena/shared/widgets/app_text_field.dart';
import 'package:jp_auction_arena/shared/widgets/app_ui_feedback.dart';

/// Auto-generates the next player number for the current auction.
final playerNoProvider = Provider<int>((ref) {
  throw UnimplementedError('Use playerNoNotifierProvider instead');
});

class PlayerRegistrationForm extends ConsumerStatefulWidget {
  final Player? playerToEdit;
  final VoidCallback? onSaved;

  const PlayerRegistrationForm({
    super.key,
    this.playerToEdit,
    this.onSaved,
  });

  @override
  ConsumerState<PlayerRegistrationForm> createState() => _PlayerRegistrationFormState();
}

class _PlayerRegistrationFormState extends ConsumerState<PlayerRegistrationForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _mobileController = TextEditingController();
  final _ageController = TextEditingController();
  final _villageController = TextEditingController();
  final _basePriceController = TextEditingController();
  final _jerseyNumberController = TextEditingController();
  final _cricHeroesController = TextEditingController();
  final _matchesController = TextEditingController();
  final _runsController = TextEditingController();
  final _wicketsController = TextEditingController();
  final _battingAverageController = TextEditingController();
  final _strikeRateController = TextEditingController();
  final _economyController = TextEditingController();

  String? _photoUrl;
  Uint8List? _photoBytes;
  String _category = 'All-Rounder';
  String _battingStyle = 'Right Hand Bat';
  String _bowlingStyle = 'Right Arm Medium';
  bool _isSaving = false;
  String? _autoPlayerId;
  int _nextPlayerNo = 1;

  static const List<String> _categories = [
    'Batsman',
    'Bowler',
    'All-Rounder',
    'Wicket-Keeper',
  ];

  static const List<String> _battingStyles = [
    'Right Hand Bat',
    'Left Hand Bat',
  ];

  static const List<String> _bowlingStyles = [
    'Right Arm Medium',
    'Right Arm Fast',
    'Right Arm Off Spin',
    'Right Arm Leg Spin',
    'Left Arm Medium',
    'Left Arm Fast',
    'Left Arm Orthodox Spin',
    'Left Arm Chinaman',
    'Does not bowl',
  ];

  @override
  void initState() {
    super.initState();
    _loadNextPlayerNo();
    if (widget.playerToEdit != null) {
      _populateEditFields(widget.playerToEdit!);
    }
  }

  Future<void> _loadNextPlayerNo() async {
    final activeAuction = ref.read(activeAuctionProvider);
    if (activeAuction == null) return;
    final repo = ref.read(playerRepositoryProvider);
    final players = await repo.getByAuctionId(activeAuction.id);
    final maxNo = players.fold<int>(0, (max, p) => p.playerNo > max ? p.playerNo : max);
    setState(() {
      _nextPlayerNo = maxNo + 1;
      _autoPlayerId = 'P${_nextPlayerNo.toString().padLeft(3, '0')}';
      if (widget.playerToEdit == null) {
        _jerseyNumberController.text = _nextPlayerNo.toString();
      }
    });
  }

  void _populateEditFields(Player p) {
    _nameController.text = p.name;
    _mobileController.text = p.mobile ?? '';
    _ageController.text = p.age.toString();
    _villageController.text = p.village;
    _basePriceController.text = p.basePrice.toStringAsFixed(0);
    _jerseyNumberController.text = p.playerNo.toString();
    _cricHeroesController.text = p.cricHeroesUrl ?? '';
    _matchesController.text = p.matches.toString();
    _runsController.text = p.runs.toString();
    _wicketsController.text = p.wickets.toString();
    _battingAverageController.text = p.battingAverage.toStringAsFixed(2);
    _strikeRateController.text = p.strikeRate.toStringAsFixed(2);
    _economyController.text = p.economy.toStringAsFixed(2);
    _photoUrl = p.photoBase64;
    _category = p.category;
    _battingStyle = p.battingStyle;
    _bowlingStyle = p.bowlingStyle;
    _autoPlayerId = p.id;
    _nextPlayerNo = p.playerNo;
  }

  Future<void> _pickPhoto() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 80,
    );
    if (picked == null) return;
    final bytes = await picked.readAsBytes();
    setState(() {
      _photoBytes = bytes;
      _photoUrl = null;
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final activeAuction = ref.read(activeAuctionProvider);
    if (activeAuction == null) {
      AppToast.showError(context, 'No active auction selected.');
      return;
    }

    setState(() => _isSaving = true);
    try {
      String? finalPhotoUrl = _photoUrl;
      if (_photoBytes != null) {
        final supabaseRepo = ref.read(supabasePlayerRepositoryProvider);
        final playerId = _autoPlayerId ?? 'p_${DateTime.now().millisecondsSinceEpoch}';
        final url = await supabaseRepo.uploadPhoto(activeAuction.id, playerId, _photoBytes!);
        if (url != null) finalPhotoUrl = url;
      }

      final player = Player(
        id: widget.playerToEdit?.id ??
            (_autoPlayerId ?? 'p_${DateTime.now().millisecondsSinceEpoch}'),
        auctionId: activeAuction.id,
        playerNo: int.tryParse(_jerseyNumberController.text) ?? _nextPlayerNo,
        name: _nameController.text.trim(),
        mobile: _mobileController.text.trim().isEmpty
            ? null
            : _mobileController.text.trim(),
        photoBase64: finalPhotoUrl,
        age: int.tryParse(_ageController.text) ?? 20,
        village: _villageController.text.trim(),
        category: _category,
        battingStyle: _battingStyle,
        bowlingStyle: _bowlingStyle,
        cricHeroesUrl: _cricHeroesController.text.trim().isEmpty
            ? null
            : _cricHeroesController.text.trim(),
        matches: int.tryParse(_matchesController.text) ?? 0,
        runs: int.tryParse(_runsController.text) ?? 0,
        wickets: int.tryParse(_wicketsController.text) ?? 0,
        battingAverage: double.tryParse(_battingAverageController.text) ?? 0.0,
        strikeRate: double.tryParse(_strikeRateController.text) ?? 0.0,
        economy: double.tryParse(_economyController.text) ?? 0.0,
        basePrice: double.tryParse(_basePriceController.text) ?? 10000.0,
      );

      // Duplicate check by mobile
      final repo = ref.read(supabasePlayerRepositoryProvider);
      if (_mobileController.text.trim().isNotEmpty) {
        final existing = await repo.getByAuctionId(activeAuction.id);
        final duplicate = existing.any((p) {
          if (p.id == player.id) return false;
          return p.mobile?.trim().toLowerCase() ==
              _mobileController.text.trim().toLowerCase();
        });
        if (duplicate) {
          if (mounted) {
            AppToast.showError(
              context,
              'A player with mobile "${_mobileController.text.trim()}" already exists.',
            );
            setState(() => _isSaving = false);
          }
          return;
        }
      }

      await repo.save(player);
      if (mounted) {
        AppToast.showSuccess(
          context,
          'Player "${player.name}" saved successfully.',
        );
        widget.onSaved?.call();
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        AppToast.showError(context, 'Save failed: $e');
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _mobileController.dispose();
    _ageController.dispose();
    _villageController.dispose();
    _basePriceController.dispose();
    _jerseyNumberController.dispose();
    _cricHeroesController.dispose();
    _matchesController.dispose();
    _runsController.dispose();
    _wicketsController.dispose();
    _battingAverageController.dispose();
    _strikeRateController.dispose();
    _economyController.dispose();
    super.dispose();
  }

  Widget _buildPhotoPicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Player Photo',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 10),
        Center(
          child: Stack(
            children: [
              Container(
                width: 110,
                height: 110,
                decoration: BoxDecoration(
                  color: AppColors.surfaceLight,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.primaryBlue,
                    width: 2,
                  ),
                ),
                child: _photoBytes != null
                    ? ClipOval(
                        child: Image.memory(
                          _photoBytes!,
                          fit: BoxFit.cover,
                          width: 110,
                          height: 110,
                        ),
                      )
                    : _photoUrl != null
                        ? ClipOval(
                            child: Image.network(
                              _photoUrl!,
                              fit: BoxFit.cover,
                              width: 110,
                              height: 110,
                              errorBuilder: (_, __, ___) => const Icon(
                                Icons.person_outline,
                                size: 44,
                                color: AppColors.textMuted,
                              ),
                            ),
                          )
                        : const Icon(
                            Icons.camera_alt_rounded,
                            size: 44,
                            color: AppColors.textMuted,
                          ),
              ),
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.accentPink,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(
                      Icons.edit_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                    onPressed: _pickPhoto,
                    padding: const EdgeInsets.all(6),
                    constraints: const BoxConstraints(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDropdown(String label, String value, List<String> items, ValueChanged<String> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surfaceLight.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(AppTheme.buttonRadius),
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              icon: const Icon(
                Icons.keyboard_arrow_down_rounded,
                color: AppColors.textSecondary,
                size: 20,
              ),
              items: items.map((item) => DropdownMenuItem(
                value: item,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  child: Text(
                    item,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                    ),
                  ),
                ),
              )).toList(),
              onChanged: (String? newValue) {
                if (newValue != null) onChanged(newValue);
              },
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.playerToEdit != null;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(20),
      child: GlassCard(
        backgroundColor: AppColors.card,
        width: 620,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        gradient: AppColors.accentGradient,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.person_add_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isEdit ? 'Edit Player' : 'Add New Player',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            isEdit
                                ? 'Update player details for "${widget.playerToEdit!.name}"'
                                : 'Register a cricketer for the auction pool',
                            style: const TextStyle(
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
                const SizedBox(height: 24),

                // CricHeroes Profile URL + Fetch button (TOP)
                Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: AppTextField(
                        controller: _cricHeroesController,
                        label: 'CricHeroes Profile URL',
                        hintText: 'https://cricheroes.in/profile/...',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 1,
                      child: SizedBox(
                        height: 56,
                        child: GradientButton(
                          onPressed: () {
                            AppToast.showSuccess(context, 'Fetch from CricHeroes (coming soon)');
                          },
                          icon: Icons.refresh_rounded,
                          label: 'Fetch',
                          width: double.infinity,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Auto Player ID
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Player ID',
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceLight.withValues(alpha: 0.5),
                              borderRadius: BorderRadius.circular(AppTheme.buttonRadius),
                              border: Border.all(color: AppColors.cardBorder),
                            ),
                            child: Text(
                              _autoPlayerId ?? 'Auto-generating...',
                              style: const TextStyle(
                                color: AppColors.accentPink,
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: AppTextField(
                        controller: _jerseyNumberController,
                        label: 'Jersey Number',
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Photo picker full width
                _buildPhotoPicker(),
                const SizedBox(height: 20),

                // Two-column fields: Name | Mobile
                Row(
                  children: [
                    Expanded(
                      child: AppTextField(
                        controller: _nameController,
                        label: 'Full Name',
                        required: true,
                        hintText: 'Enter player full name',
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'Name is required';
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: AppTextField(
                        controller: _mobileController,
                        label: 'Mobile Number',
                        required: true,
                        hintText: '10-digit mobile',
                        keyboardType: TextInputType.phone,
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'Mobile is required';
                          final digits = v.replaceAll(RegExp(r'\D'), '');
                          if (digits.length < 10) return 'Enter valid mobile';
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Two-column fields: Age | Village
                Row(
                  children: [
                    Expanded(
                      child: AppTextField(
                        controller: _ageController,
                        label: 'Age',
                        hintText: '18-50',
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: AppTextField(
                        controller: _villageController,
                        label: 'City / Village',
                        hintText: 'Enter hometown',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Role, Batting, Bowling in three columns
                Row(
                  children: [
                    Expanded(
                      child: _buildDropdown('Role / Category', _category, _categories, (v) => setState(() => _category = v)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildDropdown('Batting Style', _battingStyle, _battingStyles, (v) => setState(() => _battingStyle = v)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildDropdown('Bowling Style', _bowlingStyle, _bowlingStyles, (v) => setState(() => _bowlingStyle = v)),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Base Price
                Row(
                  children: [
                    Expanded(
                      child: AppTextField(
                        controller: _basePriceController,
                        label: 'Base Price (₹)',
                        required: true,
                        hintText: '10000',
                        keyboardType: TextInputType.number,
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'Base price required';
                          if (double.tryParse(v) == null) return 'Enter amount';
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Cricket Statistics
                const Text(
                  'Cricket Statistics',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: AppTextField(
                        controller: _matchesController,
                        label: 'Matches',
                        hintText: '0',
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: AppTextField(
                        controller: _runsController,
                        label: 'Runs',
                        hintText: '0',
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: AppTextField(
                        controller: _wicketsController,
                        label: 'Wickets',
                        hintText: '0',
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: AppTextField(
                        controller: _battingAverageController,
                        label: 'Batting Average',
                        hintText: '0.00',
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: AppTextField(
                        controller: _strikeRateController,
                        label: 'Strike Rate',
                        hintText: '0.00',
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: AppTextField(
                        controller: _economyController,
                        label: 'Bowling Economy',
                        hintText: '0.00',
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 26),

                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    GradientButton(
                      onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
                      icon: Icons.cancel_rounded,
                      label: 'Cancel',
                      width: 120,
                      gradient: const LinearGradient(
                        colors: [AppColors.textMuted, AppColors.textMuted],
                      ),
                    ),
                    const SizedBox(width: 12),
                    GradientButton(
                      onPressed: _isSaving ? null : _save,
                      icon: Icons.save_rounded,
                      label: isEdit ? 'Update Player' : 'Save Player',
                      width: 160,
                      isLoading: _isSaving,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
