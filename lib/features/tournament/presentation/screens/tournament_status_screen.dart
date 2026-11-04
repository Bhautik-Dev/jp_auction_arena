import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:jp_auction_arena/core/theme/app_spacing.dart';
import 'package:jp_auction_arena/features/auth/application/auth_providers.dart';
import 'package:jp_auction_arena/features/tournament/domain/errors/tournament_exceptions.dart';
import 'package:jp_auction_arena/features/tournament/domain/models/tournament.dart';
import 'package:jp_auction_arena/features/tournament/domain/models/tournament_status.dart';
import 'package:jp_auction_arena/features/tournament/domain/services/tournament_management_service.dart';
import 'package:jp_auction_arena/features/tournament/presentation/providers/tournament_providers.dart';
import 'package:jp_auction_arena/features/tournament/presentation/widgets/tournament_widgets.dart';
import 'package:jp_auction_arena/features/dashboard/application/dashboard_providers.dart';
import 'package:jp_auction_arena/shared/widgets/app_confirmation_dialog.dart';
import 'package:jp_auction_arena/shared/widgets/app_states.dart';

class TournamentStatusScreen extends ConsumerWidget {
  const TournamentStatusScreen({required this.tournamentId, super.key});

  final String tournamentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tournament = ref.watch(tournamentByIdProvider(tournamentId));
    return tournament.when(
      loading: () => const AppLoadingIndicator(),
      error: (error, stackTrace) => AppErrorState(
        error: error,
        onRetry: () => ref.invalidate(tournamentByIdProvider(tournamentId)),
      ),
      data: (value) => value == null
          ? const AppEmptyState(
              title: 'Tournament not found',
              message: 'This tournament may have been removed.',
            )
          : _StatusActions(tournament: value),
    );
  }
}

class _StatusActions extends ConsumerStatefulWidget {
  const _StatusActions({required this.tournament});

  final Tournament tournament;

  @override
  ConsumerState<_StatusActions> createState() => _StatusActionsState();
}

class _StatusActionsState extends ConsumerState<_StatusActions> {
  bool _updating = false;
  String? _errorMessage;

  @override
  Widget build(BuildContext context) {
    final tournament = widget.tournament;
    final nextStatuses = TournamentStatus.values
        .where(
          (status) => TournamentManagementService.canTransition(
            tournament.status,
            status,
          ),
        )
        .toList();
    return ListView(
      children: [
        Text(
          'Tournament Status Management',
          style: Theme.of(context).textTheme.headlineLarge,
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(tournament.name, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            const Text('Current status'),
            const SizedBox(width: AppSpacing.md),
            TournamentStatusChip(status: tournament.status),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        const Text(
          'Valid next steps are shown below. Only one tournament may be active. '
          'Completed records are retained and can be archived; archived records '
          'can be restored to Completed.',
        ),
        const SizedBox(height: AppSpacing.lg),
        if (nextStatuses.isEmpty)
          const Text('No status transitions are available.')
        else
          for (final status in nextStatuses) ...[
            Card(
              child: ListTile(
                leading: const Icon(Icons.sync_alt),
                title: Text('Change to ${status.label}'),
                subtitle: Text(_description(status)),
                trailing: const Icon(Icons.chevron_right),
                onTap: _updating ? null : () => _changeStatus(status),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
        if (_errorMessage != null) ...[
          const SizedBox(height: AppSpacing.md),
          Text(
            _errorMessage!,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ],
      ],
    );
  }

  Future<void> _changeStatus(TournamentStatus nextStatus) async {
    final confirmed = await AppConfirmationDialog.show(
      context,
      title: 'Change tournament status?',
      message: _confirmationMessage(nextStatus),
      confirmLabel: 'Change status',
    );
    if (!confirmed || !mounted) return;

    final actor = ref
        .read(authSessionProvider)
        .whenOrNull(data: (session) => session?.user);
    if (actor == null) {
      setState(
        () => _errorMessage = 'Your session has expired. Sign in again.',
      );
      return;
    }

    setState(() {
      _updating = true;
      _errorMessage = null;
    });
    try {
      await ref
          .read(tournamentManagementServiceProvider)
          .changeStatus(actor, widget.tournament.id, nextStatus);
      ref.invalidate(tournamentsProvider);
      ref.invalidate(tournamentHistoryProvider);
      ref.invalidate(tournamentByIdProvider(widget.tournament.id));
      ref.invalidate(dashboardSnapshotProvider);
      if (mounted) context.go('/app/tournaments/${widget.tournament.id}');
    } on TournamentAuthorizationException catch (error) {
      if (mounted) setState(() => _errorMessage = error.message);
    } on TournamentTransitionException catch (error) {
      if (mounted) setState(() => _errorMessage = error.message);
    } on TournamentValidationException catch (error) {
      if (mounted) setState(() => _errorMessage = error.message);
    } on StateError catch (error) {
      if (mounted) setState(() => _errorMessage = error.message);
    } finally {
      if (mounted) setState(() => _updating = false);
    }
  }

  String _description(TournamentStatus status) => switch (status) {
    TournamentStatus.draft => 'Return this tournament to draft setup.',
    TournamentStatus.upcoming => 'Mark this tournament as ready for its dates.',
    TournamentStatus.active =>
      'Activate this tournament. The repository prevents a second active tournament.',
    TournamentStatus.completed =>
      'Mark the tournament complete while retaining its history.',
    TournamentStatus.archived =>
      'Archive this completed tournament as a read-only historical record.',
    TournamentStatus.cancelled => 'Cancel this tournament.',
  };

  String _confirmationMessage(TournamentStatus status) => switch (status) {
    TournamentStatus.active =>
      'This will activate the tournament. If another tournament is active, '
          'the change will be rejected.',
    TournamentStatus.archived =>
      'This retains the completed tournament in read-only history.',
    TournamentStatus.completed =>
      'The tournament remains available and can later be archived.',
    TournamentStatus.cancelled =>
      'This marks the tournament cancelled. It will remain in the records.',
    _ => 'This updates the tournament lifecycle status.',
  };
}
