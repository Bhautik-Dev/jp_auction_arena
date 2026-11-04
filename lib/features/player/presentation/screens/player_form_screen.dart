import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:jp_auction_arena/core/constants/app_colors.dart';
import 'package:jp_auction_arena/core/responsive/app_breakpoints.dart';
import 'package:jp_auction_arena/features/player/domain/errors/player_exceptions.dart';
import 'package:jp_auction_arena/features/player/domain/models/player.dart';
import 'package:jp_auction_arena/features/player/domain/models/player_category.dart';
import 'package:jp_auction_arena/features/player/domain/models/player_status.dart';
import 'package:jp_auction_arena/features/player/presentation/providers/player_providers.dart';
import 'package:jp_auction_arena/features/player/presentation/widgets/player_avatar.dart';

class PlayerFormScreen extends ConsumerStatefulWidget {
  const PlayerFormScreen({this.playerId, super.key});

  final String? playerId;
  bool get isEditing => playerId != null;

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
  PlayerStatus _status = PlayerStatus.available;
  String? _teamId;
  Player? _existingPlayer;
  bool _isLoading = false;
  bool _isSaving = false;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    if (widget.isEditing) _loadPlayer();
  }

  Future<void> _loadPlayer() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });
    try {
      final player = await ref
          .read(playerRepositoryProvider)
          .getPlayerById(widget.playerId!);
      if (player == null) {
        _loadError = 'Player not found.';
      } else {
        _existingPlayer = player;
        _nameController.text = player.name;
        _battingController.text = player.battingStyle;
        _bowlingController.text = player.bowlingStyle;
        _priceController.text = player.basePrice.toString();
        _contactController.text = player.contactNumber ?? '';
        _category = player.category;
        _status = player.status;
        _teamId = player.assignedTeamId;
      }
    } catch (error) {
      _loadError = 'Failed to load player: $error';
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _battingController.dispose();
    _bowlingController.dispose();
    _priceController.dispose();
    _contactController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final now = DateTime.now();
    final previous = _existingPlayer;
    final contact = _contactController.text.trim();
    final player = Player(
      id: previous?.id ?? '',
      name: _nameController.text.trim(),
      category: _category!,
      battingStyle: _battingController.text.trim(),
      bowlingStyle: _bowlingController.text.trim(),
      basePrice: int.parse(_priceController.text.trim()),
      contactNumber: contact.isEmpty ? null : contact,
      status: _status,
      assignedTeamId: _teamId,
      createdAt: previous?.createdAt ?? now,
      updatedAt: now,
    );
    setState(() => _isSaving = true);
    try {
      if (previous == null) {
        await ref.read(playerListProvider.notifier).createPlayer(player);
      } else {
        await ref.read(playerListProvider.notifier).updatePlayer(player);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              previous == null ? 'Player added.' : 'Player updated.',
            ),
          ),
        );
        context.pop();
      }
    } on PlayerException catch (error) {
      if (mounted) _showError(error.message);
    } catch (error) {
      if (mounted) _showError('Failed to save player: $error');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.danger),
    );
  }

  @override
  Widget build(BuildContext context) {
    final teamsAsync = ref.watch(teamsForPlayerAssignmentProvider);
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_loadError != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Player')),
        body: Center(child: Text(_loadError!)),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEditing ? 'Edit Player' : 'Add Player'),
      ),
      body: teamsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Could not load teams for assignment: $error'),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: () =>
                      ref.invalidate(teamsForPlayerAssignmentProvider),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
        data: (teams) => Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final wide =
                    constraints.maxWidth >= AppBreakpoints.compact + 100;
                return Form(
                  key: _formKey,
                  child: ListView(
                    padding: const EdgeInsets.all(24),
                    children: [
                      _PlayerIdentityCard(
                        player: _previewPlayer(),
                        isEditing: widget.isEditing,
                      ),
                      const SizedBox(height: 20),
                      _section(context, 'Player information'),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _nameController,
                        textCapitalization: TextCapitalization.words,
                        decoration: const InputDecoration(
                          labelText: 'Player name *',
                          prefixIcon: Icon(Icons.person_outline),
                        ),
                        validator: (value) =>
                            value == null || value.trim().isEmpty
                            ? 'Enter a player name'
                            : null,
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<PlayerCategory>(
                        initialValue: _category,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Player category *',
                          prefixIcon: Icon(Icons.sports_cricket_outlined),
                        ),
                        items: [
                          for (final category in PlayerCategory.values)
                            DropdownMenuItem(
                              value: category,
                              child: Text(category.label),
                            ),
                        ],
                        onChanged: (value) => setState(() => _category = value),
                        validator: (value) =>
                            value == null ? 'Choose a category' : null,
                      ),
                      const SizedBox(height: 16),
                      _fieldPair(
                        wide,
                        TextFormField(
                          controller: _battingController,
                          textCapitalization: TextCapitalization.words,
                          decoration: const InputDecoration(
                            labelText: 'Batting style',
                            hintText: 'e.g. Right-hand bat',
                          ),
                        ),
                        TextFormField(
                          controller: _bowlingController,
                          textCapitalization: TextCapitalization.words,
                          decoration: const InputDecoration(
                            labelText: 'Bowling style',
                            hintText: 'e.g. Right-arm medium',
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      _fieldPair(
                        wide,
                        TextFormField(
                          controller: _priceController,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          decoration: const InputDecoration(
                            labelText: 'Base price (₹) *',
                            prefixIcon: Icon(Icons.currency_rupee),
                          ),
                          validator: _validatePrice,
                        ),
                        TextFormField(
                          controller: _contactController,
                          keyboardType: TextInputType.phone,
                          decoration: const InputDecoration(
                            labelText: 'Contact number',
                            prefixIcon: Icon(Icons.phone_outlined),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      _section(context, 'Status and team'),
                      const SizedBox(height: 12),
                      _fieldPair(
                        wide,
                        DropdownButtonFormField<PlayerStatus>(
                          initialValue: _status,
                          isExpanded: true,
                          decoration: const InputDecoration(
                            labelText: 'Player status',
                            prefixIcon: Icon(Icons.flag_outlined),
                          ),
                          items: [
                            for (final status in PlayerStatus.values)
                              DropdownMenuItem(
                                value: status,
                                child: Text(status.label),
                              ),
                          ],
                          onChanged: (value) {
                            if (value != null) setState(() => _status = value);
                          },
                        ),
                        DropdownButtonFormField<String?>(
                          initialValue: _teamId,
                          isExpanded: true,
                          decoration: const InputDecoration(
                            labelText: 'Assigned team',
                            prefixIcon: Icon(Icons.groups_outlined),
                          ),
                          items: [
                            const DropdownMenuItem<String?>(
                              value: null,
                              child: Text('No team assigned'),
                            ),
                            if (_teamId != null &&
                                !teams.any((team) => team.id == _teamId))
                              DropdownMenuItem<String?>(
                                value: _teamId,
                                child: const Text('Unavailable team'),
                              ),
                            for (final team in teams)
                              DropdownMenuItem<String?>(
                                value: team.id,
                                child: Text(
                                  team.name,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                          ],
                          onChanged: (value) => setState(() => _teamId = value),
                        ),
                      ),
                      const SizedBox(height: 28),
                      Wrap(
                        alignment: WrapAlignment.end,
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          OutlinedButton(
                            onPressed: _isSaving ? null : () => context.pop(),
                            child: const Text('Cancel'),
                          ),
                          FilledButton.icon(
                            onPressed: _isSaving ? null : _save,
                            icon: _isSaving
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: AppColors.white,
                                    ),
                                  )
                                : const Icon(Icons.check),
                            label: Text(
                              widget.isEditing ? 'Save changes' : 'Add player',
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Player _previewPlayer() {
    final now = DateTime(2000);
    return Player(
      id: 'preview',
      name: _nameController.text,
      category: _category ?? PlayerCategory.batsman,
      battingStyle: _battingController.text,
      bowlingStyle: _bowlingController.text,
      basePrice: int.tryParse(_priceController.text) ?? 0,
      status: _status,
      createdAt: now,
      updatedAt: now,
    );
  }

  String? _validatePrice(String? value) {
    final price = int.tryParse(value?.trim() ?? '');
    if (price == null) return 'Enter a valid base price';
    if (price <= 0) return 'Base price must be greater than zero';
    return null;
  }

  Widget _fieldPair(bool wide, Widget first, Widget second) {
    if (!wide) {
      return Column(children: [first, const SizedBox(height: 16), second]);
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: first),
        const SizedBox(width: 16),
        Expanded(child: second),
      ],
    );
  }

  Widget _section(BuildContext context, String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.w700,
        color: AppColors.neonPink,
      ),
    );
  }
}

class _PlayerIdentityCard extends StatelessWidget {
  const _PlayerIdentityCard({required this.player, required this.isEditing});

  final Player player;
  final bool isEditing;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: PlayerAvatar(player: player, size: 60),
        title: Text(
          player.name.isEmpty ? 'Player photo placeholder' : player.name,
        ),
        subtitle: Text(
          isEditing
              ? 'Profile photo upload is not available yet.'
              : 'Photo upload can be added later.',
        ),
        trailing: const Icon(Icons.image_outlined, color: AppColors.magenta),
      ),
    );
  }
}
