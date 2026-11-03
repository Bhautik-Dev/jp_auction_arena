import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:jp_auction_arena/core/constants/app_colors.dart';
import 'package:jp_auction_arena/core/responsive/app_breakpoints.dart';
import 'package:jp_auction_arena/features/team/domain/errors/team_exceptions.dart';
import 'package:jp_auction_arena/features/team/domain/models/team.dart';
import 'package:jp_auction_arena/features/team/domain/models/team_status.dart';
import 'package:jp_auction_arena/features/team/presentation/providers/team_providers.dart';
import 'package:jp_auction_arena/features/team/presentation/widgets/team_logo_view.dart';
import 'package:jp_auction_arena/features/tournament/domain/models/tournament.dart';
import 'package:jp_auction_arena/features/tournament/presentation/providers/tournament_providers.dart';

class TeamFormScreen extends ConsumerStatefulWidget {
  const TeamFormScreen({this.teamId, super.key});

  final String? teamId;

  bool get isEditing => teamId != null;

  @override
  ConsumerState<TeamFormScreen> createState() => _TeamFormScreenState();
}

class _TeamFormScreenState extends ConsumerState<TeamFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _shortNameController = TextEditingController();
  final _ownerController = TextEditingController();
  final _managerController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();

  String? _tournamentId;
  TeamLogo? _logo;
  int _primaryColorValue = AppColors.electricBlue.toARGB32();
  int _secondaryColorValue = AppColors.neonPink.toARGB32();
  Team? _existingTeam;
  bool _isLoadingTeam = false;
  bool _isSubmitting = false;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    if (widget.isEditing) _loadTeam();
  }

  Future<void> _loadTeam() async {
    setState(() {
      _isLoadingTeam = true;
      _loadError = null;
    });
    try {
      final team = await ref
          .read(teamRepositoryProvider)
          .getTeamById(widget.teamId!);
      if (team == null) {
        _loadError = 'Team not found.';
      } else {
        _existingTeam = team;
        _nameController.text = team.name;
        _shortNameController.text = team.shortName;
        _ownerController.text = team.ownerName;
        _managerController.text = team.managerName;
        _emailController.text = team.contactEmail;
        _phoneController.text = team.contactPhone;
        _tournamentId = team.tournamentId;
        _logo = team.logo;
        _primaryColorValue = team.primaryColorValue;
        _secondaryColorValue = team.secondaryColorValue;
      }
    } catch (error) {
      _loadError = 'Failed to load team: $error';
    } finally {
      if (mounted) setState(() => _isLoadingTeam = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _shortNameController.dispose();
    _ownerController.dispose();
    _managerController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _pickLogo() async {
    try {
      final logo = await ref.read(teamLogoPickerProvider).pickLogo();
      if (logo != null && mounted) setState(() => _logo = logo);
    } on Exception catch (error) {
      if (mounted) _showMessage(error.toString(), isError: true);
    }
  }

  Future<void> _submit(List<Tournament> tournaments) async {
    if (!_formKey.currentState!.validate()) return;

    final tournamentId = _tournamentId ?? tournaments.first.id;
    final now = DateTime.now();
    final previous = _existingTeam;
    final team = Team(
      id: previous?.id ?? '',
      tournamentId: tournamentId,
      name: _nameController.text.trim(),
      shortName: _shortNameController.text.trim().toUpperCase(),
      logo: _logo,
      primaryColorValue: _primaryColorValue,
      secondaryColorValue: _secondaryColorValue,
      ownerName: _ownerController.text.trim(),
      managerName: _managerController.text.trim(),
      contactEmail: _emailController.text.trim(),
      contactPhone: _phoneController.text.trim(),
      status: previous?.status ?? TeamStatus.active,
      createdAt: previous?.createdAt ?? now,
      updatedAt: now,
      hasAuctionActivity: previous?.hasAuctionActivity ?? false,
      hasPlayerAssignments: previous?.hasPlayerAssignments ?? false,
    );

    setState(() => _isSubmitting = true);
    try {
      if (previous == null) {
        await ref.read(teamListProvider.notifier).createTeam(team);
      } else {
        await ref.read(teamListProvider.notifier).updateTeam(team);
      }
      if (mounted) {
        _showMessage(previous == null ? 'Team created.' : 'Team updated.');
        context.pop();
      }
    } on TeamException catch (error) {
      if (mounted) _showMessage(error.message, isError: true);
    } catch (error) {
      if (mounted) _showMessage('Failed to save team: $error', isError: true);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tournamentsAsync = ref.watch(tournamentListProvider);

    if (_isLoadingTeam) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_loadError != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Team')),
        body: Center(child: Text(_loadError!)),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEditing ? 'Edit Team' : 'Create Team'),
      ),
      body: tournamentsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => _ErrorView(
          message: 'Failed to load tournaments: $error',
          onRetry: () => ref.invalidate(tournamentListProvider),
        ),
        data: (tournaments) {
          if (tournaments.isEmpty) {
            return const _ErrorView(
              message: 'Create a tournament before adding teams.',
            );
          }
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 800),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final wide =
                      constraints.maxWidth >= AppBreakpoints.compact + 100;
                  return Form(
                    key: _formKey,
                    child: ListView(
                      padding: const EdgeInsets.all(24),
                      children: [
                        _SectionTitle(title: 'Team identity'),
                        const SizedBox(height: 12),
                        _LogoPicker(
                          logo: _logo,
                          previewTeam: _previewTeam(),
                          onPick: _pickLogo,
                          onRemove: _logo == null
                              ? null
                              : () => setState(() => _logo = null),
                        ),
                        const SizedBox(height: 18),
                        TextFormField(
                          controller: _nameController,
                          textCapitalization: TextCapitalization.words,
                          decoration: const InputDecoration(
                            labelText: 'Team name *',
                            hintText: 'e.g. Ahmedabad Strikers',
                          ),
                          validator: _requiredValidator('Enter a team name'),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _shortNameController,
                          textCapitalization: TextCapitalization.characters,
                          decoration: const InputDecoration(
                            labelText: 'Team short name *',
                            hintText: 'e.g. AST',
                          ),
                          validator: (value) {
                            final input = value?.trim() ?? '';
                            if (input.isEmpty) return 'Enter a short name';
                            if (input.length > 10) {
                              return 'Use 10 characters or fewer';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 24),
                        _SectionTitle(title: 'Team colors'),
                        const SizedBox(height: 8),
                        _ColorPicker(
                          label: 'Primary color',
                          selectedValue: _primaryColorValue,
                          onSelected: (value) =>
                              setState(() => _primaryColorValue = value),
                        ),
                        const SizedBox(height: 12),
                        _ColorPicker(
                          label: 'Secondary color',
                          selectedValue: _secondaryColorValue,
                          onSelected: (value) =>
                              setState(() => _secondaryColorValue = value),
                        ),
                        const SizedBox(height: 24),
                        _SectionTitle(title: 'Tournament and contacts'),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          initialValue: _selectedTournament(tournaments),
                          isExpanded: true,
                          decoration: const InputDecoration(
                            labelText: 'Tournament *',
                            prefixIcon: Icon(Icons.emoji_events_outlined),
                          ),
                          items: [
                            for (final tournament in tournaments)
                              DropdownMenuItem(
                                value: tournament.id,
                                child: Text(
                                  tournament.name,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                          ],
                          onChanged: (value) =>
                              setState(() => _tournamentId = value),
                          validator: (value) =>
                              value == null ? 'Choose a tournament' : null,
                        ),
                        const SizedBox(height: 16),
                        _responsivePair(
                          wide,
                          _textField(
                            controller: _ownerController,
                            label: 'Owner name *',
                            validator: _requiredValidator(
                              'Enter the owner name',
                            ),
                          ),
                          _textField(
                            controller: _managerController,
                            label: 'Manager name *',
                            validator: _requiredValidator(
                              'Enter the manager name',
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        _responsivePair(
                          wide,
                          _textField(
                            controller: _emailController,
                            label: 'Contact email *',
                            keyboardType: TextInputType.emailAddress,
                            validator: _emailValidator,
                          ),
                          _textField(
                            controller: _phoneController,
                            label: 'Contact phone *',
                            keyboardType: TextInputType.phone,
                            validator: _phoneValidator,
                          ),
                        ),
                        const SizedBox(height: 28),
                        Wrap(
                          alignment: WrapAlignment.end,
                          spacing: 12,
                          runSpacing: 12,
                          children: [
                            OutlinedButton(
                              onPressed: _isSubmitting
                                  ? null
                                  : () => context.pop(),
                              child: const Text('Cancel'),
                            ),
                            FilledButton.icon(
                              onPressed: _isSubmitting
                                  ? null
                                  : () => _submit(tournaments),
                              icon: _isSubmitting
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
                                widget.isEditing
                                    ? 'Save changes'
                                    : 'Create team',
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
          );
        },
      ),
    );
  }

  Team _previewTeam() {
    return Team(
      id: 'preview',
      tournamentId: '',
      name: _nameController.text,
      shortName: _shortNameController.text,
      logo: _logo,
      primaryColorValue: _primaryColorValue,
      secondaryColorValue: _secondaryColorValue,
      ownerName: '',
      managerName: '',
      contactEmail: '',
      contactPhone: '',
      status: TeamStatus.active,
      createdAt: DateTime(2000),
      updatedAt: DateTime(2000),
    );
  }

  String? _selectedTournament(List<Tournament> tournaments) {
    if (_tournamentId != null &&
        tournaments.any((tournament) => tournament.id == _tournamentId)) {
      return _tournamentId;
    }
    return tournaments.first.id;
  }

  Widget _textField({
    required TextEditingController controller,
    required String label,
    required String? Function(String?) validator,
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      textCapitalization: keyboardType == TextInputType.emailAddress
          ? TextCapitalization.none
          : TextCapitalization.words,
      decoration: InputDecoration(labelText: label),
      validator: validator,
    );
  }

  Widget _responsivePair(bool wide, Widget first, Widget second) {
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

  String? Function(String?) _requiredValidator(String message) => (value) {
    if (value == null || value.trim().isEmpty) return message;
    return null;
  };

  String? _emailValidator(String? value) {
    final email = value?.trim() ?? '';
    if (email.isEmpty) return 'Enter a contact email';
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
      return 'Enter a valid email address';
    }
    return null;
  }

  String? _phoneValidator(String? value) {
    final phone = value?.trim() ?? '';
    if (phone.isEmpty) return 'Enter a contact phone';
    final digits = phone.replaceAll(RegExp(r'\D'), '');
    if (digits.length < 7 || digits.length > 15) {
      return 'Enter a valid phone number';
    }
    return null;
  }

  void _showMessage(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.danger : null,
      ),
    );
  }
}

class _LogoPicker extends StatelessWidget {
  const _LogoPicker({
    required this.logo,
    required this.previewTeam,
    required this.onPick,
    required this.onRemove,
  });

  final TeamLogo? logo;
  final Team previewTeam;
  final VoidCallback onPick;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        TeamLogoView(team: previewTeam, size: 64),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                logo?.fileName ?? 'Team logo (optional)',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 4),
              Text(
                'Choose an image up to 5 MB. It is kept in memory in this demo.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  OutlinedButton.icon(
                    onPressed: onPick,
                    icon: const Icon(Icons.image_outlined),
                    label: const Text('Choose image'),
                  ),
                  if (onRemove != null)
                    TextButton(
                      onPressed: onRemove,
                      child: const Text('Remove'),
                    ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ColorPicker extends StatelessWidget {
  const _ColorPicker({
    required this.label,
    required this.selectedValue,
    required this.onSelected,
  });

  final String label;
  final int selectedValue;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 8),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (final color in AppColors.teamColorOptions)
              Semantics(
                button: true,
                selected: color.toARGB32() == selectedValue,
                label: '$label ${color.toARGB32().toRadixString(16)}',
                child: InkWell(
                  onTap: () => onSelected(color.toARGB32()),
                  customBorder: const CircleBorder(),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: color.toARGB32() == selectedValue
                            ? Theme.of(context).colorScheme.onSurface
                            : Theme.of(context).colorScheme.outline,
                        width: color.toARGB32() == selectedValue ? 3 : 1,
                      ),
                    ),
                    child: color.toARGB32() == selectedValue
                        ? const Icon(
                            Icons.check,
                            size: 18,
                            color: AppColors.white,
                          )
                        : null,
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
        color: Theme.of(context).colorScheme.primary,
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, this.onRetry});

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message, textAlign: TextAlign.center),
            if (onRetry != null) ...[
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Try again'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
