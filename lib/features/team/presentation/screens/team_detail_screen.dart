import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:jp_auction_arena/core/routing/route_names.dart';
import 'package:jp_auction_arena/core/theme/app_spacing.dart';
import 'package:jp_auction_arena/features/auction/domain/models/auction.dart';
import 'package:jp_auction_arena/features/auction/domain/models/auction_status.dart';
import 'package:jp_auction_arena/features/auction/presentation/providers/auction_providers.dart';
import 'package:jp_auction_arena/features/auth/application/auth_providers.dart';
import 'package:jp_auction_arena/features/team/domain/errors/team_exceptions.dart';
import 'package:jp_auction_arena/features/team/domain/models/team.dart';
import 'package:jp_auction_arena/features/team/domain/models/team_status.dart';
import 'package:jp_auction_arena/features/team/presentation/providers/team_providers.dart';
import 'package:jp_auction_arena/shared/widgets/app_states.dart';

class TeamDetailScreen extends ConsumerWidget {
  const TeamDetailScreen({
    required this.auctionId,
    required this.teamId,
    super.key,
  });

  final String auctionId;
  final String teamId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final params = (auctionId: auctionId, teamId: teamId);
    final teamState = ref.watch(teamByIdProvider(params));
    final auctionState = ref.watch(auctionByIdProvider(auctionId));
    if (teamState.isLoading || auctionState.isLoading) {
      return const AppLoadingIndicator(label: 'Loading team details...');
    }
    if (teamState.hasError) {
      return AppErrorState(
        error: teamState.error!,
        onRetry: () => ref.invalidate(teamByIdProvider(params)),
      );
    }
    if (auctionState.hasError) {
      return AppErrorState(
        error: auctionState.error!,
        onRetry: () => ref.invalidate(auctionByIdProvider(auctionId)),
      );
    }
    return _TeamDetail(
      team: teamState.requireValue,
      auction: auctionState.requireValue,
      auctionId: auctionId,
    );
  }
}

class _TeamDetail extends ConsumerWidget {
  const _TeamDetail({
    required this.team,
    required this.auction,
    required this.auctionId,
  });

  final Team team;
  final Auction auction;
  final String auctionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final canEditAuction =
        auction.status == AuctionStatus.draft ||
        auction.status == AuctionStatus.ready;
    final purse = NumberFormat.currency(
      name: auction.baseCurrency,
      symbol: '${auction.baseCurrency} ',
      decimalDigits: 0,
    ).format(auction.totalPursePerTeam);
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        Row(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: Color(team.primaryColorValue),
              child: team.logoReference == null
                  ? Text(team.shortName)
                  : const Icon(Icons.shield_outlined),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                team.name,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
            ),
            Chip(label: Text(team.status.label)),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Text('Auction: ${auction.name}'),
        const SizedBox(height: AppSpacing.lg),
        _detail(context, 'Short name', team.shortName),
        _detail(context, 'Owner', team.ownerName),
        _detail(context, 'Manager', team.managerName),
        _detail(context, 'Contact number', _orNotSet(team.contactPhone)),
        _detail(context, 'Email', _orNotSet(team.contactEmail)),
        _detail(context, 'City', _orNotSet(team.city)),
        _detail(context, 'Description', _orNotSet(team.description)),
        _detail(context, 'Logo / image', _orNotSet(team.logoReference ?? '')),
        _detail(context, 'Team purse', purse),
        _detail(
          context,
          'Squad size',
          '${auction.minPlayersPerTeam}–${auction.maxPlayersPerTeam} players',
        ),
        _detail(
          context,
          'Team capacity',
          '${auction.maxTeams} teams for this auction',
        ),
        const SizedBox(height: AppSpacing.lg),
        Text('Management', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            if (canEditAuction && team.status != TeamStatus.archived)
              OutlinedButton.icon(
                onPressed: () => context.go(
                  RouteNames.auctionTeamEditPath(auctionId, team.id),
                ),
                icon: const Icon(Icons.edit_outlined),
                label: const Text('Edit Team'),
              ),
            if (canEditAuction && team.status == TeamStatus.active)
              OutlinedButton(
                onPressed: () => _changeStatus(
                  context,
                  ref,
                  TeamStatus.inactive,
                  'Deactivate this team?',
                ),
                child: const Text('Deactivate'),
              ),
            if (canEditAuction && team.status == TeamStatus.inactive)
              OutlinedButton(
                onPressed: () => _changeStatus(
                  context,
                  ref,
                  TeamStatus.active,
                  'Reactivate this team?',
                ),
                child: const Text('Reactivate'),
              ),
            if (canEditAuction && team.status != TeamStatus.archived)
              FilledButton.tonal(
                onPressed: () => _changeStatus(
                  context,
                  ref,
                  TeamStatus.archived,
                  'Archive this team?',
                ),
                child: const Text('Archive Team'),
              ),
            if (canEditAuction && team.status == TeamStatus.archived)
              FilledButton.tonal(
                onPressed: () => _changeStatus(
                  context,
                  ref,
                  TeamStatus.inactive,
                  'Restore this archived team?',
                ),
                child: const Text('Restore Team'),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        const Text(
          'Team registration is currently in local in-memory storage. Purse and squad limits are inherited from auction configuration; player purchases are not implemented yet.',
        ),
      ],
    );
  }

  Widget _detail(BuildContext context, String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 180,
          child: Text(label, style: Theme.of(context).textTheme.titleSmall),
        ),
        Expanded(child: Text(value)),
      ],
    ),
  );

  String _orNotSet(String value) => value.isEmpty ? 'Not set' : value;

  Future<void> _changeStatus(
    BuildContext context,
    WidgetRef ref,
    TeamStatus nextStatus,
    String title,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(
          nextStatus == TeamStatus.archived
              ? 'The team will be hidden from active registration but its record will be retained.'
              : 'Confirm the team status change.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final session = await ref.read(authSessionProvider.future);
    if (session == null) return;
    try {
      await ref
          .read(teamManagementServiceProvider)
          .updateStatus(session.user, auctionId, team.id, nextStatus);
      ref.invalidate(teamsForAuctionProvider(auctionId));
      ref.invalidate(teamByIdProvider((auctionId: auctionId, teamId: team.id)));
    } on TeamException catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.message)));
      }
    }
  }
}
