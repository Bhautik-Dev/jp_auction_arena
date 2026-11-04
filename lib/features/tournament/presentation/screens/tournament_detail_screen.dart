import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:jp_auction_arena/core/theme/app_spacing.dart';
import 'package:jp_auction_arena/core/routing/route_names.dart';
import 'package:jp_auction_arena/features/tournament/domain/models/tournament.dart';
import 'package:jp_auction_arena/features/tournament/domain/models/tournament_status.dart';
import 'package:jp_auction_arena/features/tournament/presentation/providers/tournament_providers.dart';
import 'package:jp_auction_arena/features/tournament/presentation/widgets/tournament_widgets.dart';
import 'package:jp_auction_arena/shared/widgets/app_card.dart';
import 'package:jp_auction_arena/shared/widgets/app_states.dart';

class TournamentDetailScreen extends ConsumerWidget {
  const TournamentDetailScreen({required this.tournamentId, super.key});

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
          : _TournamentDetails(tournament: value),
    );
  }
}

class _TournamentDetails extends StatelessWidget {
  const _TournamentDetails({required this.tournament});

  final Tournament tournament;

  @override
  Widget build(BuildContext context) => ListView(
    children: [
      Row(
        children: [
          Expanded(
            child: Text(
              tournament.name,
              style: Theme.of(context).textTheme.headlineLarge,
            ),
          ),
          TournamentStatusChip(status: tournament.status),
        ],
      ),
      const SizedBox(height: AppSpacing.md),
      Wrap(
        spacing: AppSpacing.md,
        runSpacing: AppSpacing.sm,
        children: [
          OutlinedButton.icon(
            onPressed: tournament.status == TournamentStatus.archived
                ? null
                : () =>
                      context.go(RouteNames.tournamentEditPath(tournament.id)),
            icon: const Icon(Icons.edit_outlined),
            label: const Text('Edit tournament'),
          ),
          FilledButton.tonalIcon(
            onPressed: () => context.go(
              '${RouteNames.tournamentDetailPath(tournament.id)}/status',
            ),
            icon: const Icon(Icons.sync_alt),
            label: const Text('Manage status'),
          ),
        ],
      ),
      const SizedBox(height: AppSpacing.lg),
      AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  child: Icon(
                    tournament.logoReference == null
                        ? Icons.emoji_events_outlined
                        : Icons.image_outlined,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    tournament.description.isEmpty
                        ? 'No tournament description provided.'
                        : tournament.description,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            _DetailRow(label: 'Location', value: tournament.city),
            _DetailRow(
              label: 'Tournament dates',
              value: tournamentDateRange(tournament),
            ),
            _DetailRow(
              label: 'Registration opens',
              value: _formatDate(tournament.registrationStartDate),
            ),
            _DetailRow(
              label: 'Registration closes',
              value: _formatDate(tournament.registrationClosingDate),
            ),
            _DetailRow(label: 'Format', value: tournament.format),
            _DetailRow(
              label: 'Participating team limit',
              value: '${tournament.numberOfParticipatingTeams}',
            ),
            _DetailRow(
              label: 'Squad size',
              value: '${tournament.minSquadSize} - ${tournament.maxSquadSize}',
            ),
            _DetailRow(label: 'Organizer', value: tournament.organizerName),
            _DetailRow(
              label: 'Contact details',
              value: tournament.contactDetails,
            ),
            if (tournament.venue.isNotEmpty)
              _DetailRow(label: 'Venue', value: tournament.venue),
            if (tournament.logoReference != null)
              _DetailRow(
                label: 'Image reference',
                value: tournament.logoReference!,
              ),
            if (tournament.additionalNotes.isNotEmpty)
              _DetailRow(
                label: 'Additional notes',
                value: tournament.additionalNotes,
              ),
          ],
        ),
      ),
      if (tournament.status == TournamentStatus.archived) ...[
        const SizedBox(height: AppSpacing.md),
        const AppCard(
          child: Text(
            'Archived tournaments are read-only. Use status management to '
            'restore this record before making edits.',
          ),
        ),
      ],
    ],
  );

  String _formatDate(DateTime? date) =>
      date == null ? 'Not set' : DateFormat.yMMMd().format(date);
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: AppSpacing.md),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 190,
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        Expanded(child: Text(value)),
      ],
    ),
  );
}
