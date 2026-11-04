import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:jp_auction_arena/core/theme/app_spacing.dart';
import 'package:jp_auction_arena/features/auth/application/auth_providers.dart';
import 'package:jp_auction_arena/features/player/domain/models/player.dart';
import 'package:jp_auction_arena/features/player/domain/models/player_category.dart';
import 'package:jp_auction_arena/features/player/domain/models/player_status.dart';
import 'package:jp_auction_arena/features/player/presentation/providers/player_providers.dart';
import 'package:jp_auction_arena/shared/widgets/app_button.dart';
import 'package:jp_auction_arena/shared/widgets/app_states.dart';
import 'package:jp_auction_arena/shared/widgets/app_text_field.dart';

class PlayerFormScreen extends ConsumerStatefulWidget {
  const PlayerFormScreen({required this.auctionId, this.playerId, super.key});

  final String auctionId;
  final String? playerId;

  @override
  ConsumerState<PlayerFormScreen> createState() => _PlayerFormScreenState();
}

class _PlayerFormScreenState extends ConsumerState<PlayerFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _imageController = TextEditingController();
  final _ageController = TextEditingController();
  final _battingController = TextEditingController();
  final _bowlingController = TextEditingController();
  final _priceController = TextEditingController();
  final _contactController = TextEditingController();
  final _matchesController = TextEditingController(text: '0');
  final _runsController = TextEditingController(text: '0');
  final _wicketsController = TextEditingController(text: '0');
  PlayerCategory? _category;
  String? _loadedPlayerId;
  bool _isSaving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _imageController.dispose();
    _ageController.dispose();
    _battingController.dispose();
    _bowlingController.dispose();
    _priceController.dispose();
    _contactController.dispose();
    _matchesController.dispose();
    _runsController.dispose();
    _wicketsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final playerId = widget.playerId;
    if (playerId == null) return _form(context, null);
    return ref
        .watch(
          playerForAuctionProvider((
            auctionId: widget.auctionId,
            playerId: playerId,
          )),
        )
        .when(
          loading: () => const AppLoadingIndicator(label: 'Loading player...'),
          error: (error, stackTrace) => AppErrorState(
            error: error,
            onRetry: () => ref.invalidate(
              playerForAuctionProvider((
                auctionId: widget.auctionId,
                playerId: playerId,
              )),
            ),
          ),
          data: (player) {
            if (_loadedPlayerId != player.id) _loadPlayer(player);
            return _form(context, player);
          },
        );
  }

  Widget _form(BuildContext context, Player? player) => Scaffold(
    body: SafeArea(
      child: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            Text(
              player == null ? 'Player Registration' : 'Edit Player',
              style: Theme.of(context).textTheme.headlineLarge,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Player registration is scoped to this auction. Team assignment and sold/unsold status are managed by auction results.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: AppSpacing.lg),
            AppTextField(
              label: 'Player name',
              controller: _nameController,
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'Enter a player name'
                  : null,
            ),
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              label: 'Player image reference (optional)',
              controller: _imageController,
            ),
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              label: 'Age (optional)',
              controller: _ageController,
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.trim().isEmpty) return null;
                final age = int.tryParse(value.trim());
                return age == null || age < 1 || age > 100
                    ? 'Enter an age from 1 to 100'
                    : null;
              },
            ),
            const SizedBox(height: AppSpacing.md),
            DropdownButtonFormField<PlayerCategory>(
              initialValue: _category,
              decoration: const InputDecoration(labelText: 'Category'),
              items: PlayerCategory.values
                  .map(
                    (category) => DropdownMenuItem(
                      value: category,
                      child: Text(category.label),
                    ),
                  )
                  .toList(),
              onChanged: (value) => setState(() => _category = value),
              validator: (value) => value == null ? 'Choose a category' : null,
            ),
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              label: 'Batting style',
              controller: _battingController,
            ),
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              label: 'Bowling style',
              controller: _bowlingController,
            ),
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              label: 'Base price',
              controller: _priceController,
              keyboardType: TextInputType.number,
              validator: (value) {
                final price = int.tryParse(value?.trim() ?? '');
                return price == null || price <= 0
                    ? 'Enter a valid base price'
                    : null;
              },
            ),
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              label: 'Contact number (optional)',
              controller: _contactController,
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Player statistics',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              label: 'Matches played',
              controller: _matchesController,
              keyboardType: TextInputType.number,
              validator: _validateNonNegative,
            ),
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              label: 'Runs scored',
              controller: _runsController,
              keyboardType: TextInputType.number,
              validator: _validateNonNegative,
            ),
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              label: 'Wickets taken',
              controller: _wicketsController,
              keyboardType: TextInputType.number,
              validator: _validateNonNegative,
            ),
            const SizedBox(height: AppSpacing.lg),
            AppPrimaryButton(
              label: _isSaving
                  ? 'Saving...'
                  : player == null
                  ? 'Add player'
                  : 'Save changes',
              onPressed: _isSaving ? null : () => _submit(player),
            ),
          ],
        ),
      ),
    ),
  );

  String? _validateNonNegative(String? value) {
    final number = int.tryParse(value?.trim() ?? '');
    return number == null || number < 0
        ? 'Enter a valid non-negative number'
        : null;
  }

  void _loadPlayer(Player player) {
    _loadedPlayerId = player.id;
    _nameController.text = player.name;
    _imageController.text = player.imageReference ?? '';
    _ageController.text = player.age?.toString() ?? '';
    _battingController.text = player.battingStyle;
    _bowlingController.text = player.bowlingStyle;
    _priceController.text = player.basePrice.toString();
    _contactController.text = player.contactNumber ?? '';
    _matchesController.text = player.matchesPlayed.toString();
    _runsController.text = player.runsScored.toString();
    _wicketsController.text = player.wicketsTaken.toString();
    _category = player.category;
  }

  Future<void> _submit(Player? existing) async {
    if (!_formKey.currentState!.validate()) return;
    final session = ref
        .read(authSessionProvider)
        .whenOrNull(data: (value) => value);
    if (session == null) return;
    setState(() => _isSaving = true);
    try {
      final now = DateTime.now();
      final player = Player(
        id: existing?.id ?? '',
        auctionId: widget.auctionId,
        name: _nameController.text.trim(),
        imageReference: _imageController.text.trim().isEmpty
            ? null
            : _imageController.text.trim(),
        category: _category!,
        battingStyle: _battingController.text.trim(),
        bowlingStyle: _bowlingController.text.trim(),
        basePrice: int.parse(_priceController.text.trim()),
        contactNumber: _contactController.text.trim().isEmpty
            ? null
            : _contactController.text.trim(),
        status: existing?.status ?? PlayerStatus.available,
        assignedTeamId: existing?.assignedTeamId,
        age: int.tryParse(_ageController.text.trim()),
        matchesPlayed: int.parse(_matchesController.text.trim()),
        runsScored: int.parse(_runsController.text.trim()),
        wicketsTaken: int.parse(_wicketsController.text.trim()),
        createdAt: existing?.createdAt ?? now,
        updatedAt: now,
      );
      final service = ref.read(playerManagementServiceProvider);
      if (existing == null) {
        await service.create(session.user, player);
      } else {
        await service.update(session.user, player);
      }
      ref.invalidate(playersForAuctionProvider);
      if (mounted) context.pop();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.toString())));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
}
