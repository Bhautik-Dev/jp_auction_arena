import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:jp_auction_arena/core/theme/app_spacing.dart';
import 'package:jp_auction_arena/features/player/domain/models/player.dart';
import 'package:jp_auction_arena/features/player/domain/models/player_category.dart';
import 'package:jp_auction_arena/features/player/domain/models/player_status.dart';
import 'package:jp_auction_arena/features/player/presentation/providers/player_providers.dart';
import 'package:jp_auction_arena/shared/widgets/app_button.dart';
import 'package:jp_auction_arena/shared/widgets/app_text_field.dart';

class PlayerFormScreen extends ConsumerStatefulWidget {
  const PlayerFormScreen({super.key});

  @override
  ConsumerState<PlayerFormScreen> createState() => _PlayerFormScreenState();
}

class _PlayerFormScreenState extends ConsumerState<PlayerFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _battingController = TextEditingController();
  final _bowlingController = TextEditingController();
  final _priceController = TextEditingController();
  final _contactController = TextEditingController();
  PlayerCategory? _category;
  bool _isSaving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _battingController.dispose();
    _bowlingController.dispose();
    _priceController.dispose();
    _contactController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Form(
        key: _formKey,
        child: ListView(
          children: [
            Text(
              'Player Registration',
              style: Theme.of(context).textTheme.headlineLarge,
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
            AppPrimaryButton(
              label: 'Add player',
              onPressed: _isSaving ? null : _submit,
            ),
          ],
        ),
      ),
    ),
  );

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    try {
      await ref
          .read(playerRepositoryProvider)
          .createPlayer(
            Player(
              id: '',
              name: _nameController.text.trim(),
              category: _category!,
              battingStyle: _battingController.text.trim(),
              bowlingStyle: _bowlingController.text.trim(),
              basePrice: int.parse(_priceController.text.trim()),
              contactNumber: _contactController.text.trim().isEmpty
                  ? null
                  : _contactController.text.trim(),
              status: PlayerStatus.available,
              assignedTeamId: null,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            ),
          );
      ref.invalidate(playersProvider);
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
