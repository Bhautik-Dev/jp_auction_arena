import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:jp_auction_arena/core/routing/route_names.dart';
import 'package:jp_auction_arena/core/theme/app_spacing.dart';
import 'package:jp_auction_arena/features/auction/domain/models/auction_status.dart';
import 'package:jp_auction_arena/features/auction/presentation/providers/auction_providers.dart';
import 'package:jp_auction_arena/features/auth/application/auth_providers.dart';
import 'package:jp_auction_arena/features/team/domain/errors/team_exceptions.dart';
import 'package:jp_auction_arena/features/team/domain/models/team_status.dart';
import 'package:jp_auction_arena/features/team/presentation/providers/team_providers.dart';
import 'package:jp_auction_arena/shared/widgets/app_card.dart';
import 'package:jp_auction_arena/shared/widgets/app_states.dart';

class TeamListScreen extends ConsumerStatefulWidget {
  const TeamListScreen({this.auctionId, super.key});

  final String? auctionId;

  @override
  ConsumerState<TeamListScreen> createState() => _TeamListScreenState();
}

class _TeamListScreenState extends ConsumerState<TeamListScreen> {
  final _search = TextEditingController();
  String? _selectedAuctionId;
  TeamStatus? _status;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _selectedAuctionId = widget.auctionId;
    _search.addListener(() => setState(() => _query = _search.text.trim()));
  }

  @override
  void didUpdateWidget(covariant TeamListScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.auctionId != oldWidget.auctionId) {
      _selectedAuctionId = widget.auctionId;
    }
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(AppSpacing.lg),
    children: [
      Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: AppSpacing.md,
        runSpacing: AppSpacing.sm,
        children: [
          Text('Teams', style: Theme.of(context).textTheme.headlineLarge),
        ],
      ),
      const SizedBox(height: AppSpacing.lg),
      ref
          .watch(auctionsProvider)
          .when(
            loading: () => const SizedBox(
              height: 100,
              child: AppLoadingIndicator(label: 'Loading auctions...'),
            ),
            error: (error, stackTrace) => AppErrorState(
              error: error,
              onRetry: () => ref.invalidate(auctionsProvider),
            ),
            data: (auctions) {
              if (auctions.isEmpty) {
                return const AppEmptyState(
                  title: 'No auctions available',
                  message:
                      'Create or get assigned to an auction to register teams.',
                );
              }
              final defaultAuction = auctions.firstWhere(
                (auction) =>
                    auction.status == AuctionStatus.draft ||
                    auction.status == AuctionStatus.ready,
                orElse: () => auctions.first,
              );
              final selectedAuction =
                  auctions.any((auction) => auction.id == _selectedAuctionId)
                  ? _selectedAuctionId
                  : defaultAuction.id;
              final currentAuction = auctions.firstWhere(
                (auction) => auction.id == selectedAuction,
              );
              final canModifyTeams =
                  currentAuction.status == AuctionStatus.draft ||
                  currentAuction.status == AuctionStatus.ready;
              if (_selectedAuctionId != selectedAuction) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) {
                    setState(() => _selectedAuctionId = selectedAuction);
                  }
                });
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DropdownButtonFormField<String>(
                    initialValue: selectedAuction,
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: 'Auction'),
                    items: [
                      for (final auction in auctions)
                        DropdownMenuItem(
                          value: auction.id,
                          child: Text(
                            auction.name,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                    onChanged: widget.auctionId == null
                        ? (value) => setState(() => _selectedAuctionId = value)
                        : null,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: [
                      if (canModifyTeams)
                        FilledButton.icon(
                          onPressed: () => context.go(
                            RouteNames.auctionTeamCreatePath(selectedAuction!),
                          ),
                          icon: const Icon(Icons.add),
                          label: const Text('Create Team'),
                        ),
                      if (canModifyTeams)
                        OutlinedButton.icon(
                          onPressed: _importCsv,
                          icon: const Icon(Icons.upload_file_outlined),
                          label: const Text('Import CSV'),
                        ),
                      OutlinedButton.icon(
                        onPressed: _exportCsv,
                        icon: const Icon(Icons.copy_all_outlined),
                        label: const Text('Copy CSV export'),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  if (_selectedAuctionId != null) ...[
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final searchField = TextField(
                          controller: _search,
                          decoration: const InputDecoration(
                            labelText: 'Search teams',
                            prefixIcon: Icon(Icons.search),
                          ),
                        );
                        final statusFilter = DropdownButton<TeamStatus?>(
                          value: _status,
                          isExpanded: true,
                          hint: const Text('All statuses'),
                          items: [
                            const DropdownMenuItem<TeamStatus?>(
                              value: null,
                              child: Text('All statuses'),
                            ),
                            for (final status in TeamStatus.values)
                              DropdownMenuItem(
                                value: status,
                                child: Text(status.label),
                              ),
                          ],
                          onChanged: (value) => setState(() => _status = value),
                        );
                        if (constraints.maxWidth < 640) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              searchField,
                              const SizedBox(height: AppSpacing.sm),
                              statusFilter,
                            ],
                          );
                        }
                        return Row(
                          children: [
                            Expanded(child: searchField),
                            const SizedBox(width: AppSpacing.md),
                            SizedBox(width: 180, child: statusFilter),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _teamResults(
                      _selectedAuctionId!,
                      canModifyTeams: canModifyTeams,
                    ),
                  ],
                ],
              );
            },
          ),
    ],
  );

  Widget _teamResults(String auctionId, {required bool canModifyTeams}) => ref
      .watch(teamsForAuctionProvider(auctionId))
      .when(
        loading: () => const SizedBox(
          height: 200,
          child: AppLoadingIndicator(label: 'Loading teams...'),
        ),
        error: (error, stackTrace) => AppErrorState(
          error: error,
          onRetry: () => ref.invalidate(teamsForAuctionProvider(auctionId)),
        ),
        data: (teams) {
          final filtered = teams.where((team) {
            final query = _query.toLowerCase();
            final matchesQuery =
                query.isEmpty ||
                '${team.name} ${team.shortName} ${team.ownerName} '
                        '${team.managerName} ${team.city}'
                    .toLowerCase()
                    .contains(query);
            return matchesQuery && (_status == null || team.status == _status);
          }).toList();
          if (filtered.isEmpty) {
            return AppEmptyState(
              title: teams.isEmpty ? 'No teams registered' : 'No teams found',
              message: teams.isEmpty
                  ? 'Register teams for this auction. Team purse and squad limits follow auction settings.'
                  : 'Try a different search or status filter.',
              action: teams.isEmpty && canModifyTeams
                  ? FilledButton.icon(
                      onPressed: () => context.go(
                        RouteNames.auctionTeamCreatePath(auctionId),
                      ),
                      icon: const Icon(Icons.add),
                      label: const Text('Register first team'),
                    )
                  : null,
            );
          }
          return Column(
            children: [
              for (final team in filtered) ...[
                AppCard(
                  onTap: () => context.go(
                    RouteNames.auctionTeamDetailPath(auctionId, team.id),
                  ),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Color(team.primaryColorValue),
                      child: team.logoReference == null
                          ? Text(team.shortName)
                          : const Icon(Icons.shield_outlined),
                    ),
                    title: Text(team.name),
                    subtitle: Text(
                      '${team.shortName} · ${team.city.isEmpty ? 'City not set' : team.city} · Owner: ${team.ownerName}',
                    ),
                    trailing: Chip(label: Text(team.status.label)),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
              ],
            ],
          );
        },
      );

  Future<void> _exportCsv() async {
    final auctionId = _selectedAuctionId;
    final messenger = ScaffoldMessenger.of(context);
    final session = await ref.read(authSessionProvider.future);
    if (auctionId == null || session == null) return;
    try {
      final csv = await ref
          .read(teamManagementServiceProvider)
          .exportCsv(session.user, auctionId);
      await Clipboard.setData(ClipboardData(text: csv));
      if (mounted) {
        messenger.showSnackBar(
          const SnackBar(content: Text('Team CSV copied to clipboard.')),
        );
      }
    } on TeamException catch (error) {
      _showError(error.message);
    }
  }

  Future<void> _importCsv() async {
    final auctionId = _selectedAuctionId;
    final session = await ref.read(authSessionProvider.future);
    if (!mounted || auctionId == null || session == null) return;
    final controller = TextEditingController();
    final csv = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Import teams from CSV'),
        content: SizedBox(
          width: 600,
          child: TextField(
            controller: controller,
            minLines: 5,
            maxLines: 12,
            decoration: const InputDecoration(
              hintText: 'Paste CSV including the header row',
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Validate and import'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (csv == null || !mounted) return;
    try {
      final imported = await ref
          .read(teamManagementServiceProvider)
          .importCsv(session.user, auctionId, csv);
      ref.invalidate(teamsForAuctionProvider(auctionId));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${imported.length} teams imported.')),
        );
      }
    } on TeamException catch (error) {
      _showError(error.message);
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}
