import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:jp_auction_arena/core/routing/route_names.dart';
import 'package:jp_auction_arena/core/theme/app_spacing.dart';
import 'package:jp_auction_arena/features/auth/application/auth_providers.dart';
import 'package:jp_auction_arena/features/tournament/domain/errors/tournament_exceptions.dart';
import 'package:jp_auction_arena/features/tournament/domain/models/tournament.dart';
import 'package:jp_auction_arena/features/tournament/domain/models/tournament_status.dart';
import 'package:jp_auction_arena/features/tournament/presentation/providers/tournament_providers.dart';
import 'package:jp_auction_arena/features/tournament/presentation/widgets/tournament_widgets.dart';
import 'package:jp_auction_arena/features/dashboard/application/dashboard_providers.dart';
import 'package:jp_auction_arena/shared/widgets/app_button.dart';
import 'package:jp_auction_arena/shared/widgets/app_states.dart';

class TournamentFormScreen extends ConsumerWidget {
  const TournamentFormScreen({this.tournamentId, super.key});

  final String? tournamentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (tournamentId == null) {
      return const _TournamentFormContent();
    }
    final tournament = ref.watch(tournamentByIdProvider(tournamentId!));
    return tournament.when(
      loading: () => const AppLoadingIndicator(),
      error: (error, stackTrace) => AppErrorState(
        error: error,
        onRetry: () => ref.invalidate(tournamentByIdProvider(tournamentId!)),
      ),
      data: (value) => value == null
          ? const AppEmptyState(
              title: 'Tournament not found',
              message: 'This tournament may have been removed.',
            )
          : _TournamentFormContent(tournament: value),
    );
  }
}

class _TournamentFormContent extends ConsumerStatefulWidget {
  const _TournamentFormContent({this.tournament});

  final Tournament? tournament;

  @override
  ConsumerState<_TournamentFormContent> createState() =>
      _TournamentFormContentState();
}

class _TournamentFormContentState
    extends ConsumerState<_TournamentFormContent> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _description;
  late final TextEditingController _location;
  late final TextEditingController _logo;
  late final TextEditingController _teams;
  late final TextEditingController _minSquad;
  late final TextEditingController _maxSquad;
  late final TextEditingController _organizer;
  late final TextEditingController _contact;
  late final TextEditingController _notes;
  late DateTime _startDate;
  late DateTime _endDate;
  late DateTime _registrationStartDate;
  late DateTime _registrationClosingDate;
  late String _format;
  late TournamentStatus _newStatus;
  bool _saving = false;
  String? _errorMessage;

  Tournament? get _tournament => widget.tournament;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    final start = _tournament?.startDate ?? now.add(const Duration(days: 30));
    _name = TextEditingController(text: _tournament?.name ?? '');
    _description = TextEditingController(text: _tournament?.description ?? '');
    _location = TextEditingController(text: _tournament?.city ?? '');
    _logo = TextEditingController(text: _tournament?.logoReference ?? '');
    _teams = TextEditingController(
      text: (_tournament?.maxTeams ?? 8).toString(),
    );
    _minSquad = TextEditingController(
      text: (_tournament?.minSquadSize ?? 11).toString(),
    );
    _maxSquad = TextEditingController(
      text: (_tournament?.maxSquadSize ?? 15).toString(),
    );
    _organizer = TextEditingController(text: _tournament?.organizerName ?? '');
    _contact = TextEditingController(text: _tournament?.contactDetails ?? '');
    _notes = TextEditingController(text: _tournament?.additionalNotes ?? '');
    _startDate = start;
    _endDate = _tournament?.endDate ?? start.add(const Duration(days: 14));
    _registrationStartDate = _tournament?.registrationStartDate ?? now;
    _registrationClosingDate =
        _tournament?.registrationClosingDate ??
        start.subtract(const Duration(days: 1));
    _format = _tournament?.format ?? 'T20';
    _newStatus = _tournament?.status ?? TournamentStatus.draft;
  }

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    _location.dispose();
    _logo.dispose();
    _teams.dispose();
    _minSquad.dispose();
    _maxSquad.dispose();
    _organizer.dispose();
    _contact.dispose();
    _notes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = _tournament != null;
    return ListView(
      children: [
        Text(
          isEditing ? 'Edit Tournament' : 'Create Tournament',
          style: Theme.of(context).textTheme.headlineLarge,
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          isEditing
              ? 'Update tournament information and save your changes.'
              : 'Create a tournament record. New tournaments start as Draft or Upcoming.',
        ),
        const SizedBox(height: AppSpacing.lg),
        Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TournamentField(
                controller: _name,
                label: 'Tournament name *',
                validator: _required('Tournament name is required.'),
              ),
              const SizedBox(height: AppSpacing.md),
              TournamentField(
                controller: _description,
                label: 'Description',
                maxLines: 3,
              ),
              const SizedBox(height: AppSpacing.md),
              TournamentField(
                controller: _location,
                label: 'Tournament location *',
                validator: _required('Tournament location is required.'),
              ),
              const SizedBox(height: AppSpacing.md),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Row(
                    children: [
                      const CircleAvatar(
                        radius: 26,
                        child: Icon(Icons.image_outlined),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      const Expanded(
                        child: Text(
                          'Tournament logo / image placeholder. Local image '
                          'upload is not enabled in this phase.',
                        ),
                      ),
                      IconButton(
                        tooltip: 'Clear image reference',
                        onPressed: _logo.clear,
                        icon: const Icon(Icons.clear),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              TournamentField(
                controller: _logo,
                label: 'Image reference (optional)',
              ),
              const SizedBox(height: AppSpacing.md),
              _dateField(
                'Tournament start date *',
                _startDate,
                (value) => setState(() => _startDate = value),
              ),
              const SizedBox(height: AppSpacing.md),
              _dateField(
                'Tournament end date *',
                _endDate,
                (value) => setState(() => _endDate = value),
              ),
              const SizedBox(height: AppSpacing.md),
              _dateField(
                'Registration start date *',
                _registrationStartDate,
                (value) => setState(() => _registrationStartDate = value),
              ),
              const SizedBox(height: AppSpacing.md),
              _dateField(
                'Registration closing date *',
                _registrationClosingDate,
                (value) => setState(() => _registrationClosingDate = value),
              ),
              const SizedBox(height: AppSpacing.md),
              DropdownButtonFormField<String>(
                initialValue: _format,
                decoration: const InputDecoration(
                  labelText: 'Tournament format *',
                ),
                items: const [
                  DropdownMenuItem(value: 'T10', child: Text('T10')),
                  DropdownMenuItem(value: 'T20', child: Text('T20')),
                  DropdownMenuItem(value: 'ODI', child: Text('ODI')),
                  DropdownMenuItem(value: 'Test', child: Text('Test')),
                  DropdownMenuItem(value: 'Custom', child: Text('Custom')),
                ],
                onChanged: (value) =>
                    setState(() => _format = value ?? _format),
              ),
              const SizedBox(height: AppSpacing.md),
              _numberField(
                _teams,
                'Number of participating teams *',
                minimum: 2,
              ),
              const SizedBox(height: AppSpacing.md),
              _numberField(_minSquad, 'Minimum squad size *', minimum: 1),
              const SizedBox(height: AppSpacing.md),
              _numberField(_maxSquad, 'Maximum squad size *', minimum: 1),
              const SizedBox(height: AppSpacing.md),
              TournamentField(
                controller: _organizer,
                label: 'Organizer name *',
                validator: _required('Organizer name is required.'),
              ),
              const SizedBox(height: AppSpacing.md),
              TournamentField(
                controller: _contact,
                label: 'Contact details *',
                keyboardType: TextInputType.emailAddress,
                validator: _required('Contact details are required.'),
              ),
              const SizedBox(height: AppSpacing.md),
              TournamentField(
                controller: _notes,
                label: 'Additional notes',
                maxLines: 3,
              ),
              if (!isEditing) ...[
                const SizedBox(height: AppSpacing.md),
                DropdownButtonFormField<TournamentStatus>(
                  initialValue: _newStatus,
                  decoration: const InputDecoration(
                    labelText: 'Initial tournament status',
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: TournamentStatus.draft,
                      child: Text('Draft'),
                    ),
                    DropdownMenuItem(
                      value: TournamentStatus.upcoming,
                      child: Text('Upcoming'),
                    ),
                  ],
                  onChanged: (value) => setState(
                    () => _newStatus = value ?? TournamentStatus.draft,
                  ),
                ),
              ],
              if (_errorMessage != null) ...[
                const SizedBox(height: AppSpacing.md),
                Text(
                  _errorMessage!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
              const SizedBox(height: AppSpacing.lg),
              Wrap(
                spacing: AppSpacing.md,
                runSpacing: AppSpacing.sm,
                children: [
                  AppPrimaryButton(
                    label: _saving ? 'Saving...' : 'Save Tournament',
                    icon: Icons.save_outlined,
                    onPressed: _saving ? null : _save,
                  ),
                  AppSecondaryButton(
                    label: 'Cancel',
                    onPressed: () => context.go(
                      _tournament == null
                          ? RouteNames.tournaments
                          : RouteNames.tournamentDetailPath(_tournament!.id),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _dateField(
    String label,
    DateTime value,
    ValueChanged<DateTime> onSelected,
  ) => TournamentDateField(
    label: label,
    value: value,
    onTap: () async {
      final selected = await showDatePicker(
        context: context,
        initialDate: value,
        firstDate: DateTime(2000),
        lastDate: DateTime(2100),
      );
      if (selected != null) onSelected(selected);
    },
  );

  Widget _numberField(
    TextEditingController controller,
    String label, {
    required int minimum,
  }) => TournamentField(
    controller: controller,
    label: label,
    keyboardType: TextInputType.number,
    validator: (value) {
      final parsed = int.tryParse(value ?? '');
      if (parsed == null || parsed < minimum) {
        return 'Enter a whole number of at least $minimum.';
      }
      return null;
    },
  );

  String? Function(String?) _required(String message) =>
      (value) => value == null || value.trim().isEmpty ? message : null;

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _errorMessage = null;
    });
    final actor = ref
        .read(authSessionProvider)
        .whenOrNull(data: (session) => session?.user);
    if (actor == null) {
      setState(() {
        _saving = false;
        _errorMessage = 'Your session has expired. Sign in again to continue.';
      });
      return;
    }

    final old = _tournament;
    final newName = _name.text.trim();
    final tournament = Tournament(
      id: old?.id ?? '',
      name: newName,
      shortName: old?.shortName.isNotEmpty == true
          ? old!.shortName
          : _shortName(newName),
      seasonYear: _startDate.year.toString(),
      startDate: _startDate,
      endDate: _endDate,
      city: _location.text.trim(),
      venue: old?.venue ?? '',
      maxTeams: int.parse(_teams.text),
      status: old?.status ?? _newStatus,
      createdAt: old?.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
      description: _description.text.trim(),
      logoReference: _logo.text.trim().isEmpty ? null : _logo.text.trim(),
      registrationStartDate: _registrationStartDate,
      registrationClosingDate: _registrationClosingDate,
      format: _format,
      minSquadSize: int.parse(_minSquad.text),
      maxSquadSize: int.parse(_maxSquad.text),
      organizerName: _organizer.text.trim(),
      contactDetails: _contact.text.trim(),
      additionalNotes: _notes.text.trim(),
      hasAuctionTransactions: old?.hasAuctionTransactions ?? false,
    );

    try {
      final service = ref.read(tournamentManagementServiceProvider);
      final saved = old == null
          ? await service.create(actor, tournament)
          : await service.update(actor, tournament);
      if (old == null) {
        ref.read(authSessionProvider.notifier).assignTournament(saved.id);
      }
      _invalidateTournamentData();
      if (!mounted) return;
      context.go(RouteNames.tournamentDetailPath(saved.id));
    } on TournamentValidationException catch (error) {
      if (!mounted) return;
      setState(() => _errorMessage = error.message);
    } on TournamentAuthorizationException catch (error) {
      if (!mounted) return;
      setState(() => _errorMessage = error.message);
    } on TournamentTransitionException catch (error) {
      if (!mounted) return;
      setState(() => _errorMessage = error.message);
    } on StateError catch (error) {
      if (!mounted) return;
      setState(() => _errorMessage = 'Unable to save tournament: $error');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _invalidateTournamentData() {
    ref.invalidate(tournamentsProvider);
    ref.invalidate(tournamentHistoryProvider);
    ref.invalidate(dashboardSnapshotProvider);
    if (_tournament != null) {
      ref.invalidate(tournamentByIdProvider(_tournament!.id));
    }
  }

  String _shortName(String value) {
    final words = value.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty);
    final prefix = words.take(3).map((word) => word[0]).join().toUpperCase();
    return prefix.isEmpty ? 'TOURNAMENT' : '$prefix ${_startDate.year}';
  }
}
