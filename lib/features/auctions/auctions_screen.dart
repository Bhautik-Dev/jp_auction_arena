import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../core/routing/route_names.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/gradient_button.dart';
import '../../data/models/models.dart';
import '../../data/repositories/repositories.dart';

class AuctionsScreen extends ConsumerStatefulWidget {
  const AuctionsScreen({super.key});

  @override
  ConsumerState<AuctionsScreen> createState() => _AuctionsScreenState();
}

class _AuctionsScreenState extends ConsumerState<AuctionsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  AuctionStatus? _selectedStatusFilter;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auctionsAsync = ref.watch(auctionsListProvider);
    final activeAuction = ref.watch(activeAuctionProvider);
    final allTeams = ref.watch(allTeamsListProvider).value ?? [];
    final allPlayers = ref.watch(allPlayersListProvider).value ?? [];

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Page Title and Top Action
            _buildHeader(context),
            const SizedBox(height: 20),

            // Search Bar & Status Filter Chips
            _buildSearchAndFilters(),
            const SizedBox(height: 24),

            // Main Content: Grid or Empty State
            auctionsAsync.when(
              data: (auctions) {
                // Filter by search query
                var filtered = auctions.where((a) {
                  final matchesSearch = _searchQuery.isEmpty ||
                      a.name.toLowerCase().contains(_searchQuery) ||
                      a.venue.toLowerCase().contains(_searchQuery) ||
                      a.description.toLowerCase().contains(_searchQuery);

                  final matchesStatus = _selectedStatusFilter == null ||
                      a.status == _selectedStatusFilter;

                  return matchesSearch && matchesStatus;
                }).toList();

                if (auctions.isEmpty) {
                  return _buildEmptyState(
                    title: 'No Tournaments Created Yet',
                    subtitle:
                        'Create your first tournament auction to register teams, draft players, and enter the live hammer arena.',
                    buttonLabel: 'Create your first auction',
                  );
                }

                if (filtered.isEmpty) {
                  return _buildEmptyState(
                    title: 'No Matching Tournaments Found',
                    subtitle:
                        'No auctions match the search "$_searchQuery" with selected status filter. Try clearing filters.',
                    buttonLabel: 'Clear Search & Filters',
                    onButtonPressed: () {
                      setState(() {
                        _searchController.clear();
                        _searchQuery = '';
                        _selectedStatusFilter = null;
                      });
                    },
                  );
                }

                return LayoutBuilder(
                  builder: (context, constraints) {
                    final crossAxisCount = constraints.maxWidth >= 1150
                        ? 3
                        : (constraints.maxWidth >= 720 ? 2 : 1);

                    final spacing = 18.0;
                    final totalSpacing = (crossAxisCount - 1) * spacing;
                    final cardWidth =
                        (constraints.maxWidth - totalSpacing) / crossAxisCount;

                    return Wrap(
                      spacing: spacing,
                      runSpacing: spacing,
                      children: filtered.map((auction) {
                        final isActive = activeAuction?.id == auction.id;
                        final auctionTeams = allTeams
                            .where((t) => t.auctionId == auction.id)
                            .toList();
                        final auctionPlayers = allPlayers
                            .where((p) => p.auctionId == auction.id)
                            .toList();
                        final soldPlayersCount = auctionPlayers
                            .where((p) => p.status == PlayerStatus.sold)
                            .length;

                        return SizedBox(
                          width: cardWidth,
                          child: _buildAuctionCard(
                            context: context,
                            auction: auction,
                            isActive: isActive,
                            teams: auctionTeams,
                            players: auctionPlayers,
                            soldCount: soldPlayersCount,
                          ),
                        );
                      }).toList(),
                    );
                  },
                );
              },
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(48),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (e, _) => Center(
                child: Text('Error loading auctions: $e',
                    style: const TextStyle(color: AppColors.error)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 1. HEADER
  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primaryBlue.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: AppColors.primaryBlue.withValues(alpha: 0.3),
                ),
              ),
              child: const Icon(
                Icons.emoji_events_rounded,
                color: AppColors.primaryBlue,
                size: 26,
              ),
            ),
            const SizedBox(width: 16),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'My Tournaments & Auctions',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'Manage tournaments, duplicate setups, configure purse, and track results',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ],
        ),
        GradientButton(
          onPressed: () => context.go(RouteNames.createAuctionPath),
          icon: Icons.add_rounded,
          label: 'New Tournament',
        ),
      ],
    );
  }

  // 2. SEARCH & STATUS FILTERS
  Widget _buildSearchAndFilters() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            // Search Input Field
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: (val) {
                    setState(() {
                      _searchQuery = val.trim().toLowerCase();
                    });
                  },
                  decoration: InputDecoration(
                    hintText: 'Search by tournament name, venue, or details...',
                    prefixIcon: const Icon(Icons.search_rounded,
                        color: AppColors.primaryBlue),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded,
                                color: AppColors.textMuted),
                            onPressed: () {
                              setState(() {
                                _searchController.clear();
                                _searchQuery = '';
                              });
                            },
                          )
                        : null,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Status Filter Chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              const Text(
                'Status: ',
                style: TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 8),
              _buildFilterChip(
                label: 'All',
                isSelected: _selectedStatusFilter == null,
                onSelected: () => setState(() => _selectedStatusFilter = null),
              ),
              const SizedBox(width: 8),
              _buildFilterChip(
                label: 'Live',
                status: AuctionStatus.live,
                accentColor: AppColors.statusLive,
                isSelected: _selectedStatusFilter == AuctionStatus.live,
                onSelected: () => setState(
                    () => _selectedStatusFilter = AuctionStatus.live),
              ),
              const SizedBox(width: 8),
              _buildFilterChip(
                label: 'Draft',
                status: AuctionStatus.draft,
                accentColor: AppColors.primaryBlue,
                isSelected: _selectedStatusFilter == AuctionStatus.draft,
                onSelected: () => setState(
                    () => _selectedStatusFilter = AuctionStatus.draft),
              ),
              const SizedBox(width: 8),
              _buildFilterChip(
                label: 'Paused',
                status: AuctionStatus.paused,
                accentColor: AppColors.warning,
                isSelected: _selectedStatusFilter == AuctionStatus.paused,
                onSelected: () => setState(
                    () => _selectedStatusFilter = AuctionStatus.paused),
              ),
              const SizedBox(width: 8),
              _buildFilterChip(
                label: 'Completed',
                status: AuctionStatus.completed,
                accentColor: AppColors.success,
                isSelected: _selectedStatusFilter == AuctionStatus.completed,
                onSelected: () => setState(
                    () => _selectedStatusFilter = AuctionStatus.completed),
              ),
              const SizedBox(width: 8),
              _buildFilterChip(
                label: 'Archived',
                status: AuctionStatus.archived,
                accentColor: AppColors.textMuted,
                isSelected: _selectedStatusFilter == AuctionStatus.archived,
                onSelected: () => setState(
                    () => _selectedStatusFilter = AuctionStatus.archived),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChip({
    required String label,
    AuctionStatus? status,
    Color? accentColor,
    required bool isSelected,
    required VoidCallback onSelected,
  }) {
    final color = accentColor ?? AppColors.accentPink;

    return InkWell(
      onTap: onSelected,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? color.withValues(alpha: 0.22)
              : AppColors.surfaceLight.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? color : AppColors.cardBorder,
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isSelected) ...[
              CircleAvatar(radius: 4, backgroundColor: color),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : AppColors.textSecondary,
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 3. AUCTION CARD
  Widget _buildAuctionCard({
    required BuildContext context,
    required Auction auction,
    required bool isActive,
    required List<Team> teams,
    required List<Player> players,
    required int soldCount,
  }) {
    final statusColor = _getStatusColor(auction.status);
    final formattedDate =
        DateFormat('dd MMM yyyy, hh:mm a').format(auction.startDateTime);

    return GlassCard(
      padding: const EdgeInsets.all(20),
      borderColor: isActive ? AppColors.accentPink : AppColors.cardBorder,
      hasGlow: isActive,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Row: Logo + Name + Status Chip + 3-Dot Popup Menu
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Logo / Avatar
              _buildAuctionLogo(auction),
              const SizedBox(width: 14),

              // Title, Venue & Active tag
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            auction.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isActive) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.accentPink.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppColors.accentPink),
                            ),
                            child: const Text(
                              'ACTIVE',
                              style: TextStyle(
                                color: AppColors.accentPink,
                                fontSize: 9,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        const Icon(Icons.location_on_outlined,
                            size: 13, color: AppColors.textMuted),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            auction.venue.isNotEmpty
                                ? auction.venue
                                : 'Venue Not Specified',
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),

              // Status chip
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: statusColor.withValues(alpha: 0.6), width: 1),
                ),
                child: Text(
                  auction.status.displayName.toUpperCase(),
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
              ),

              // 3-Dot Popup Menu
              _buildThreeDotMenu(context, auction, isActive),
            ],
          ),
          const SizedBox(height: 14),

          // Date & Time
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.surfaceLight.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.event_rounded,
                    size: 14, color: AppColors.primaryBlue),
                const SizedBox(width: 6),
                Text(
                  formattedDate,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Mini Stats: Teams x/y, Players, Sold
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.surfaceLight.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildMiniStat(
                  label: 'Teams',
                  value: '${teams.length}/${auction.numberOfTeams}',
                  icon: Icons.groups_rounded,
                  color: AppColors.primaryBlue,
                ),
                Container(
                    width: 1, height: 28, color: AppColors.cardBorder),
                _buildMiniStat(
                  label: 'Players',
                  value: '${players.length}',
                  icon: Icons.person_rounded,
                  color: AppColors.secondaryPurple,
                ),
                Container(
                    width: 1, height: 28, color: AppColors.cardBorder),
                _buildMiniStat(
                  label: 'Sold',
                  value: '$soldCount',
                  icon: Icons.how_to_reg_rounded,
                  color: AppColors.success,
                ),
                Container(
                    width: 1, height: 28, color: AppColors.cardBorder),
                _buildMiniStat(
                  label: 'Purse/Team',
                  value: CurrencyFormatter.formatShort(auction.teamPurse),
                  icon: Icons.currency_rupee_rounded,
                  color: AppColors.gold,
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // Card Action Buttons
          Row(
            children: [
              // 1. View Results
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    ref.read(activeAuctionIdProvider.notifier).setAuctionId(auction.id);
                    context.go(RouteNames.resultsPath);
                  },
                  icon: const Icon(Icons.assessment_outlined, size: 16),
                  label: const Text('View Results', style: TextStyle(fontSize: 12)),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                  ),
                ),
              ),
              const SizedBox(width: 10),

              // 2. Reopen (if completed) OR Go Live (if draft/paused/live)
              if (auction.status == AuctionStatus.completed ||
                  auction.status == AuctionStatus.archived)
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _handleReopenAuction(auction),
                    icon: const Icon(Icons.restart_alt_rounded, size: 16),
                    label: const Text('Reopen', style: TextStyle(fontSize: 12)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.secondaryPurple,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                    ),
                  ),
                )
              else
                Expanded(
                  child: GradientButton(
                    height: 40,
                    onPressed: () {
                      ref.read(activeAuctionIdProvider.notifier).setAuctionId(auction.id);
                      context.go(RouteNames.livePath);
                    },
                    icon: Icons.gavel_rounded,
                    label: 'Go Live',
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAuctionLogo(Auction auction) {
    if (auction.logoBase64 != null && auction.logoBase64!.isNotEmpty) {
      try {
        final bytes = base64Decode(auction.logoBase64!);
        return ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.memory(
            bytes,
            width: 44,
            height: 44,
            fit: BoxFit.cover,
          ),
        );
      } catch (_) {}
    }

    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primaryBlue.withValues(alpha: 0.8),
            AppColors.secondaryPurple.withValues(alpha: 0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryBlue.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Center(
        child: Text(
          auction.name.isNotEmpty ? auction.name[0].toUpperCase() : 'A',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }

  Widget _buildMiniStat({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: color),
            const SizedBox(width: 4),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textMuted,
            fontSize: 10,
          ),
        ),
      ],
    );
  }

  // 4. THREE-DOT POPUP MENU
  Widget _buildThreeDotMenu(
      BuildContext context, Auction auction, bool isActive) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert_rounded,
          color: AppColors.textSecondary, size: 20),
      color: AppColors.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.cardBorder, width: 1.2),
      ),
      onSelected: (value) async {
        switch (value) {
          case 'set_active':
            ref.read(activeAuctionIdProvider.notifier).setAuctionId(auction.id);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('"${auction.name}" is now the active auction!'),
                backgroundColor: AppColors.success,
              ),
            );
            break;

          case 'reopen':
            _handleReopenAuction(auction);
            break;

          case 'manage_teams':
            ref.read(activeAuctionIdProvider.notifier).setAuctionId(auction.id);
            context.go(RouteNames.teamsPath);
            break;

          case 'manage_players':
            ref.read(activeAuctionIdProvider.notifier).setAuctionId(auction.id);
            context.go(RouteNames.playersPath);
            break;

          case 'registration':
            ref.read(activeAuctionIdProvider.notifier).setAuctionId(auction.id);
            context.go(RouteNames.registrationPath);
            break;

          case 'edit_settings':
            context.go(
                '${RouteNames.createAuctionPath}?editId=${Uri.encodeComponent(auction.id)}');
            break;

          case 'duplicate':
            _handleDuplicateAuction(auction);
            break;

          case 'archive':
            _handleArchiveAuction(auction);
            break;

          case 'delete':
            _handleDeleteAuction(auction);
            break;
        }
      },
      itemBuilder: (ctx) => [
        if (!isActive)
          const PopupMenuItem(
            value: 'set_active',
            child: Row(
              children: [
                Icon(Icons.check_circle_outline_rounded,
                    size: 18, color: AppColors.success),
                SizedBox(width: 10),
                Text('Set as Active Auction'),
              ],
            ),
          ),
        const PopupMenuItem(
          value: 'reopen',
          child: Row(
            children: [
              Icon(Icons.restart_alt_rounded,
                  size: 18, color: AppColors.secondaryPurple),
              SizedBox(width: 10),
              Text('Reopen Auction'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'manage_teams',
          child: Row(
            children: [
              Icon(Icons.groups_rounded,
                  size: 18, color: AppColors.primaryBlue),
              SizedBox(width: 10),
              Text('Manage Teams'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'manage_players',
          child: Row(
            children: [
              Icon(Icons.person_search_rounded,
                  size: 18, color: AppColors.accentPink),
              SizedBox(width: 10),
              Text('Manage Players'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'registration',
          child: Row(
            children: [
              Icon(Icons.app_registration_rounded,
                  size: 18, color: AppColors.gold),
              SizedBox(width: 10),
              Text('Registration Desk'),
            ],
          ),
        ),
        const PopupMenuDivider(),
        const PopupMenuItem(
          value: 'edit_settings',
          child: Row(
            children: [
              Icon(Icons.tune_rounded, size: 18, color: Colors.white),
              SizedBox(width: 10),
              Text('Edit Settings'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'duplicate',
          child: Row(
            children: [
              Icon(Icons.copy_rounded, size: 18, color: AppColors.primaryBlue),
              SizedBox(width: 10),
              Text('Duplicate Auction'),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'archive',
          child: Row(
            children: [
              Icon(
                auction.status == AuctionStatus.archived
                    ? Icons.unarchive_rounded
                    : Icons.archive_outlined,
                size: 18,
                color: AppColors.warning,
              ),
              const SizedBox(width: 10),
              Text(auction.status == AuctionStatus.archived
                  ? 'Unarchive Auction'
                  : 'Archive Auction'),
            ],
          ),
        ),
        const PopupMenuDivider(),
        const PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              Icon(Icons.delete_outline_rounded,
                  size: 18, color: AppColors.error),
              SizedBox(width: 10),
              Text('Delete Tournament',
                  style: TextStyle(color: AppColors.error)),
            ],
          ),
        ),
      ],
    );
  }

  // 5. ACTIONS: REOPEN, DUPLICATE, ARCHIVE, DELETE
  Future<void> _handleReopenAuction(Auction auction) async {
    final updated = auction.copyWith(status: AuctionStatus.live);
    await ref.read(auctionRepositoryProvider).save(updated);
    ref.read(activeAuctionIdProvider.notifier).setAuctionId(auction.id);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Auction "${auction.name}" is now Reopened and Live!'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  Future<void> _handleDuplicateAuction(Auction auction) async {
    final duplicated = await duplicateAuction(
      sourceAuction: auction,
      auctionRepo: ref.read(auctionRepositoryProvider),
      teamRepo: ref.read(teamRepositoryProvider),
    );

    ref.read(activeAuctionIdProvider.notifier).setAuctionId(duplicated.id);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Tournament duplicated as "${duplicated.name}" with copied franchise teams!'),
          backgroundColor: AppColors.info,
        ),
      );
    }
  }

  Future<void> _handleArchiveAuction(Auction auction) async {
    final isCurrentlyArchived = auction.status == AuctionStatus.archived;
    final newStatus =
        isCurrentlyArchived ? AuctionStatus.draft : AuctionStatus.archived;

    final updated = auction.copyWith(status: newStatus);
    await ref.read(auctionRepositoryProvider).save(updated);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isCurrentlyArchived
              ? 'Auction restored from archive.'
              : 'Auction moved to archive.'),
          backgroundColor: AppColors.warning,
        ),
      );
    }
  }

  Future<void> _handleDeleteAuction(Auction auction) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.error, width: 1.5),
        ),
        title: const Row(
          children: [
            Icon(Icons.delete_forever_rounded, color: AppColors.error, size: 26),
            SizedBox(width: 10),
            Text('Delete Tournament?', style: TextStyle(color: Colors.white)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Are you sure you want to permanently delete "${auction.name}"?',
              style: const TextStyle(color: Colors.white, fontSize: 14),
            ),
            const SizedBox(height: 10),
            const Text(
              'All corresponding franchise teams and auction bids stored in Hive will also be deleted.',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete Permanently'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await ref.read(teamRepositoryProvider).deleteByAuction(auction.id);
      await ref.read(playerRepositoryProvider).deleteByAuction(auction.id);
      await ref.read(bidRepositoryProvider).deleteByAuction(auction.id);
      await ref.read(auctionRepositoryProvider).delete(auction.id);

      if (ref.read(activeAuctionIdProvider) == auction.id) {
        ref.read(activeAuctionIdProvider.notifier).setAuctionId(null);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Tournament "${auction.name}" was deleted.'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  // 6. EMPTY STATE ILLUSTRATION
  Widget _buildEmptyState({
    required String title,
    required String subtitle,
    required String buttonLabel,
    VoidCallback? onButtonPressed,
  }) {
    return GlassCard(
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Custom Cricket Stadium / Trophy Illustration
              Container(
                width: 110,
                height: 110,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primaryBlue.withValues(alpha: 0.25),
                      AppColors.secondaryPurple.withValues(alpha: 0.25),
                      AppColors.accentPink.withValues(alpha: 0.25),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  border: Border.all(
                    color: AppColors.cardBorder,
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.secondaryPurple.withValues(alpha: 0.2),
                      blurRadius: 24,
                      spreadRadius: 4,
                    ),
                  ],
                ),
                child: const Center(
                  child: Icon(
                    Icons.emoji_events_outlined,
                    size: 54,
                    color: AppColors.gold,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.3,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              GradientButton(
                onPressed: onButtonPressed ??
                    () => context.go(RouteNames.createAuctionPath),
                icon: Icons.add_rounded,
                label: buttonLabel,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(AuctionStatus status) {
    switch (status) {
      case AuctionStatus.live:
        return AppColors.statusLive;
      case AuctionStatus.draft:
        return AppColors.primaryBlue;
      case AuctionStatus.paused:
        return AppColors.warning;
      case AuctionStatus.completed:
        return AppColors.success;
      case AuctionStatus.archived:
        return AppColors.textMuted;
    }
  }
}
