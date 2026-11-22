import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../core/routing/route_names.dart';
import '../../core/supabase/live_auction_client.dart';
import '../../core/supabase/supabase_client.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/gradient_button.dart';
import '../../data/models/models.dart';
import '../../data/repositories/repositories.dart';
import '../../shared/widgets/app_ui_feedback.dart';

/// Debug logging helper for auction operations.
void _logAuction(String tag, String message, {Object? error, StackTrace? stackTrace}) {
  final prefix = '[AUCTION]';
  final suffix = error != null ? ' ERROR: $error' : '';
  final trace = stackTrace != null ? '\n$stackTrace' : '';
  debugPrint('$prefix $tag $message$suffix$trace');
}

/// Debug logging helper for Supabase operations.
void _logSupabase(String tag, String message, {Object? error, StackTrace? stackTrace}) {
  final prefix = '[SUPABASE]';
  final suffix = error != null ? ' ERROR: $error' : '';
  final trace = stackTrace != null ? '\n$stackTrace' : '';
  debugPrint('$prefix $tag $message$suffix$trace');
}

/// Debug logging helper for errors.
void _logError(String tag, Object error, [StackTrace? stackTrace]) {
  final prefix = '[ERROR]';
  debugPrint('$prefix $tag: $error${stackTrace != null ? '\n$stackTrace' : ''}');
}

class AuctionsScreen extends ConsumerStatefulWidget {
  const AuctionsScreen({super.key});

  @override
  ConsumerState<AuctionsScreen> createState() => _AuctionsScreenState();
}

class _AuctionsScreenState extends ConsumerState<AuctionsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  AuctionStatus? _selectedStatusFilter;
  bool _isRefreshing = false;
  final Set<String> _processingAuctions = {};

  bool _isProcessing(String auctionId) => _processingAuctions.contains(auctionId);

  Future<void> _withProcessing(String auctionId, Future<void> Function() action) async {
    if (_isProcessing(auctionId)) {
      _logAuction('BLOCKED', 'Duplicate click blocked for auction $auctionId');
      return;
    }
    setState(() => _processingAuctions.add(auctionId));
    try {
      await action();
    } finally {
      if (mounted) setState(() => _processingAuctions.remove(auctionId));
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _handleRefresh() async {
    if (_isRefreshing) return;
    setState(() {
      _isRefreshing = true;
    });
    try {
      ref.invalidate(auctionsListProvider);
      await ref.read(auctionsListProvider.future);
    } catch (e) {
      if (mounted) {
        AppToast.showError(context, 'Refresh failed: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isRefreshing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auctionsAsync = ref.watch(auctionsListProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SizedBox(
              width: constraints.maxWidth,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 24),
                  _buildSearchAndFilters(),
                  const SizedBox(height: 28),
                  auctionsAsync.when(
                    data: (auctions) {
                      var filtered = auctions.where((a) {
                        final matchesSearch =
                            _searchQuery.isEmpty ||
                            a.name.toLowerCase().contains(_searchQuery) ||
                            a.venue.toLowerCase().contains(_searchQuery) ||
                            a.description.toLowerCase().contains(_searchQuery);

                        final matchesStatus =
                            _selectedStatusFilter == null ||
                            a.status == _selectedStatusFilter;

                        return matchesSearch && matchesStatus;
                      }).toList();

                      if (auctions.isEmpty) {
                        return _buildEmptyState(
                          title: 'No Tournaments Created Yet',
                          subtitle:
                              'Create your first tournament auction to register teams, draft players, and enter the live hammer arena.',
                          buttonLabel: 'Create Your First Auction',
                          onButtonPressed: () =>
                              context.go(RouteNames.createAuctionPath),
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
                          final isCompact = constraints.maxWidth < 900;
                          final isDesktop = constraints.maxWidth >= 1200;

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Active Auctions',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  if (filtered.isNotEmpty)
                                    GradientButton(
                                      onPressed: _handleRefresh,
                                      icon: Icons.refresh_rounded,
                                      label: 'Refresh All',
                                      width: 120,
                                      isLoading: _isRefreshing,
                                    ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              if (isCompact)
                                ...filtered.map(
                                  (auction) => SizedBox(
                                    width: constraints.maxWidth,
                                    child: Padding(
                                      padding: const EdgeInsets.only(
                                        bottom: 16,
                                      ),
                                      child: _buildAuctionCardCompact(
                                        context,
                                        auction,
                                      ),
                                    ),
                                  ),
                                )
                              else
                                Wrap(
                                  spacing: 20,
                                  runSpacing: 20,
                                  children: filtered.map((auction) {
                                    final cardWidth = isDesktop
                                        ? (constraints.maxWidth - 24) / 2
                                        : (constraints.maxWidth - 20);
                                    return SizedBox(
                                      width: cardWidth,
                                      child: _buildAuctionCard(
                                        context,
                                        auction,
                                      ),
                                    );
                                  }).toList(),
                                ),
                            ],
                          );
                        },
                      );
                    },
                    loading: () => LayoutBuilder(
                      builder: (context, constraints) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Active Auctions',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Wrap(
                              spacing: 20,
                              runSpacing: 20,
                              children: List.generate(
                                4,
                                (_) => SizedBox(
                                  width: 340,
                                  child: const AppSkeleton.card(height: 320),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                    error: (e, _) => AppEmptyState(
                      icon: Icons.error_outline_rounded,
                      title: 'Error Loading Auctions',
                      description: e.toString(),
                      action: GradientButton(
                        onPressed: _handleRefresh,
                        icon: Icons.refresh_rounded,
                        label: 'Retry',
                        width: 120,
                        isLoading: _isRefreshing,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  // ============ HEADER ============
  Widget _buildHeader() {
    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.primaryBlue.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.primaryBlue.withValues(alpha: 0.3),
                  ),
                ),
                child: const Icon(
                  Icons.emoji_events_rounded,
                  color: AppColors.primaryBlue,
                  size: 30,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'My Auctions',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Manage all your cricket tournaments',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              GradientButton(
                onPressed: _handleRefresh,
                icon: Icons.refresh_rounded,
                label: 'Refresh',
                width: double.infinity,
                isLoading: _isRefreshing,
              ),
              const SizedBox(height: 12),
              GradientButton(
                onPressed: () => context.go(RouteNames.createAuctionPath),
                icon: Icons.add_rounded,
                label: 'Create Auction',
                width: double.infinity,
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ============ SEARCH & STATUS FILTERS ============
  Widget _buildSearchAndFilters() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
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
                    hintText: 'Search auctions by name, venue, or details',
                    prefixIcon: const Icon(
                      Icons.search_rounded,
                      color: AppColors.primaryBlue,
                    ),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(
                              Icons.clear_rounded,
                              color: AppColors.textMuted,
                            ),
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
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.start,
          spacing: 8,
          runSpacing: 8,
          children: [
            const Text(
              'Filter by Status:',
              style: TextStyle(
                color: AppColors.textMuted,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildFilterChip(
                  label: 'All',
                  isSelected: _selectedStatusFilter == null,
                  onSelected: () =>
                      setState(() => _selectedStatusFilter = null),
                ),
                _buildFilterChip(
                  label: 'Draft',
                  status: AuctionStatus.draft,
                  accentColor: AppColors.primaryBlue,
                  isSelected: _selectedStatusFilter == AuctionStatus.draft,
                  onSelected: () => setState(
                    () => _selectedStatusFilter = AuctionStatus.draft,
                  ),
                ),
                _buildFilterChip(
                  label: 'Live',
                  status: AuctionStatus.live,
                  accentColor: AppColors.statusLive,
                  isSelected: _selectedStatusFilter == AuctionStatus.live,
                  onSelected: () => setState(
                    () => _selectedStatusFilter = AuctionStatus.live,
                  ),
                ),
                _buildFilterChip(
                  label: 'Paused',
                  status: AuctionStatus.paused,
                  accentColor: AppColors.warning,
                  isSelected: _selectedStatusFilter == AuctionStatus.paused,
                  onSelected: () => setState(
                    () => _selectedStatusFilter = AuctionStatus.paused,
                  ),
                ),
                _buildFilterChip(
                  label: 'Completed',
                  status: AuctionStatus.completed,
                  accentColor: AppColors.success,
                  isSelected: _selectedStatusFilter == AuctionStatus.completed,
                  onSelected: () => setState(
                    () => _selectedStatusFilter = AuctionStatus.completed,
                  ),
                ),
                _buildFilterChip(
                  label: 'Archived',
                  status: AuctionStatus.archived,
                  accentColor: AppColors.textMuted,
                  isSelected: _selectedStatusFilter == AuctionStatus.archived,
                  onSelected: () => setState(
                    () => _selectedStatusFilter = AuctionStatus.archived,
                  ),
                ),
              ],
            ),
          ],
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

  // ============ COMPACT AUCTION CARD (mobile) ============
  Widget _buildAuctionCardCompact(BuildContext context, Auction auction) {
    final statusColor = _getStatusColor(auction.status);
    final formattedDate = DateFormat(
      'dd MMM yyyy, hh:mm a',
    ).format(auction.startDateTime);

    return GlassCard(
      padding: const EdgeInsets.all(20),
      borderColor: AppColors.cardBorder,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              _buildAuctionLogo(auction),
              const SizedBox(width: 12),
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
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: statusColor),
                          ),
                          child: Text(
                            auction.status.displayName.toUpperCase(),
                            style: TextStyle(
                              color: statusColor,
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.5,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on_outlined,
                          size: 12,
                          color: AppColors.textMuted,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            auction.venue.isNotEmpty
                                ? auction.venue
                                : 'Venue Not Specified',
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 11,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 6,
                      children: [
                        const Icon(
                          Icons.event_rounded,
                          size: 13,
                          color: AppColors.primaryBlue,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          formattedDate,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _buildThreeDotMenu(context, auction),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 10,
            children: [
              _buildStatChip(
                'Teams',
                auction.numberOfTeams.toString(),
                Icons.groups_rounded,
                AppColors.primaryBlue,
              ),
              _buildStatChip(
                'Purse',
                formatShort(auction.teamPurse),
                Icons.currency_rupee_rounded,
                AppColors.gold,
              ),
              _buildStatChip(
                'Players',
                '0',
                Icons.person_rounded,
                AppColors.secondaryPurple,
              ),
              _buildStatChip(
                'Sold',
                '0',
                Icons.how_to_reg_rounded,
                AppColors.success,
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: GradientButton(
                  height: 40,
                  onPressed: () {
                    ref
                        .read(activeAuctionIdProvider.notifier)
                        .setAuctionId(auction.id);
                    context.go(RouteNames.resultsPath);
                  },
                  icon: Icons.assessment_outlined,
                  label: 'View Results',
                  width: double.infinity,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildAuctionActionButton(auction),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ============ DESKTOP AUCTION CARD (wide) ============
  Widget _buildAuctionCard(BuildContext context, Auction auction) {
    final statusColor = _getStatusColor(auction.status);
    final formattedDate = DateFormat(
      'dd MMM yyyy, hh:mm a',
    ).format(auction.startDateTime);

    return GlassCard(
      padding: const EdgeInsets.all(24),
      borderColor: AppColors.cardBorder,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildAuctionLogo(auction),
              const SizedBox(width: 16),
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
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: statusColor),
                          ),
                          child: Text(
                            auction.status.displayName.toUpperCase(),
                            style: TextStyle(
                              color: statusColor,
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on_outlined,
                          size: 13,
                          color: AppColors.textMuted,
                        ),
                        const SizedBox(width: 6),
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
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(
                          Icons.event_rounded,
                          size: 13,
                          color: AppColors.primaryBlue,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          formattedDate,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceLight,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.cardBorder),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          auction.numberOfTeams.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'Teams',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceLight,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.cardBorder),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          formatShort(auction.teamPurse),
                          style: const TextStyle(
                            color: AppColors.gold,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'Purse/Team',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 12),
              _buildThreeDotMenu(context, auction),
            ],
          ),
          const SizedBox(height: 20),
          Divider(color: AppColors.cardBorder),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: GradientButton(
                  height: 44,
                  onPressed: () {
                    ref
                        .read(activeAuctionIdProvider.notifier)
                        .setAuctionId(auction.id);
                    context.go(RouteNames.resultsPath);
                  },
                  icon: Icons.assessment_outlined,
                  label: 'View Results',
                  width: double.infinity,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildAuctionActionButton(auction),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ============ AUCTION LOGO ============
  Widget _buildAuctionLogo(Auction auction) {
    if (auction.logoBase64 != null && auction.logoBase64!.isNotEmpty) {
      try {
        final bytes = base64Decode(auction.logoBase64!);
        return ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.memory(bytes, width: 48, height: 48, fit: BoxFit.cover),
        );
      } catch (_) {}
    }

    return Container(
      width: 48,
      height: 48,
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
            fontSize: 20,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }

  // ============ MINI STAT CHIP ============
  Widget _buildStatChip(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            value,
            style: TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(width: 2),
          Text(
            label,
            style: TextStyle(color: AppColors.textMuted, fontSize: 9),
          ),
        ],
      ),
    );
  }

  // ============ THREE-DOT POPUP MENU ============
  Widget _buildThreeDotMenu(BuildContext context, Auction auction) {
    return PopupMenuButton<String>(
      icon: const Icon(
        Icons.more_vert_rounded,
        color: AppColors.textSecondary,
        size: 20,
      ),
      color: AppColors.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.cardBorder, width: 1.2),
      ),
      onSelected: (value) async {
        switch (value) {
          case 'control':
            ref.read(activeAuctionIdProvider.notifier).setAuctionId(auction.id);
            context.go(RouteNames.liveAuctionPath.replaceAll(':auctionId', auction.id));
            break;
          case 'end_auction':
            _handleEndAuction(auction);
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
          case 'edit_settings':
            ref.read(activeAuctionIdProvider.notifier).setAuctionId(auction.id);
            context.go(RouteNames.createAuctionPath);
            break;
          case 'delete':
            _handleDeleteAuction(auction);
            break;
        }
      },
      itemBuilder: (ctx) => [
        const PopupMenuItem(
          value: 'control',
          child: Row(
            children: [
              Icon(
                Icons.tune_rounded,
                size: 18,
                color: AppColors.primaryBlue,
              ),
              SizedBox(width: 10),
              Text('Control Auction'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'end_auction',
          child: Row(
            children: [
              Icon(
                Icons.stop_circle_rounded,
                size: 18,
                color: AppColors.error,
              ),
              SizedBox(width: 10),
              Text('End Auction', style: TextStyle(color: AppColors.error)),
            ],
          ),
        ),
        const PopupMenuDivider(),
        const PopupMenuItem(
          value: 'reopen',
          child: Row(
            children: [
              Icon(
                Icons.restart_alt_rounded,
                size: 18,
                color: AppColors.secondaryPurple,
              ),
              SizedBox(width: 10),
              Text('Reopen Auction'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'manage_teams',
          child: Row(
            children: [
              Icon(
                Icons.groups_rounded,
                size: 18,
                color: AppColors.primaryBlue,
              ),
              SizedBox(width: 10),
              Text('Manage Teams'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'manage_players',
          child: Row(
            children: [
              Icon(
                Icons.person_search_rounded,
                size: 18,
                color: AppColors.accentPink,
              ),
              SizedBox(width: 10),
              Text('Manage Players'),
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
        const PopupMenuDivider(),
        PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              Icon(
                Icons.delete_outline_rounded,
                size: 18,
                color: AppColors.error,
              ),
              const SizedBox(width: 10),
              Text('Delete Auction', style: TextStyle(color: AppColors.error)),
            ],
          ),
        ),
      ],
    );
  }

  // ============ ACTIONS ============
  Future<void> _handleReopenAuction(Auction auction) async {
    final updated = auction.copyWith(status: AuctionStatus.live);
    await ref.read(auctionRepositoryProvider).save(updated);

    if (mounted) {
      AppToast.showSuccess(context, 'Auction "${auction.name}" is now Live!');
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
            Icon(
              Icons.delete_forever_rounded,
              color: AppColors.error,
              size: 26,
            ),
            SizedBox(width: 10),
            Text('Delete Auction?', style: TextStyle(color: Colors.white)),
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
              'All corresponding franchise teams and auction bids stored in Supabase will also be deleted.',
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
        try {
          await ref.read(teamRepositoryProvider).deleteByAuction(auction.id);
          await ref.read(playerRepositoryProvider).deleteByAuction(auction.id);
          await ref.read(bidRepositoryProvider).deleteByAuction(auction.id);
          await ref.read(auctionRepositoryProvider).delete(auction.id);

          if (mounted) {
            AppToast.showSuccess(
              context,
              'Tournament "${auction.name}" deleted.',
            );
          }
        } catch (e) {
          if (mounted) {
            AppToast.showError(context, 'Failed to delete: $e');
          }
        }
      }
    }

  // ============ GO LIVE ============
  Future<void> _handleGoLive(Auction auction) async {
    _logAuction('Go Live clicked', 'auctionId=${auction.id}, name="${auction.name}", currentStatus=${auction.status.name}');

    final confirm = await AppConfirmDialog.show(
      context,
      title: 'Go Live?',
      content:
          'Are you sure you want to start the auction "${auction.name}"? This will make it available for live bidding.',
      confirmText: 'Go Live',
    );
    if (confirm != true) {
      _logAuction('Go Live cancelled', 'auctionId=${auction.id}');
      return;
    }

    await _withProcessing(auction.id, () async {
      try {
        _logSupabase('Request started', 'auctions.upsert status=live auctionId=${auction.id}');

        // Update auction status to live in Supabase
        final updated = auction.copyWith(status: AuctionStatus.live);
        await ref.read(auctionRepositoryProvider).save(updated);

        _logSupabase('Response received', 'auctions.upsert success auctionId=${auction.id}');

        // Initialize auction_state row
        final client = SupabaseClientService.instance.client;
        if (client != null) {
          _logSupabase('Request started', 'auction_state.upsert auctionId=${auction.id}');
          await client.from('auction_state').upsert({
            'id': 'state_${auction.id}',
            'auction_id': auction.id,
            'current_player_id': null,
            'current_bid_amount': null,
            'current_team_id': null,
            'timer_seconds_remaining': auction.countdownSeconds,
            'is_paused': false,
            'is_live': true,
            'last_hammered_player_id': null,
            'last_sold_team_id': null,
            'last_sold_price': null,
            'bid_count': 0,
            'updated_at': DateTime.now().toIso8601String(),
            'updated_by': '',
            'controlling_operator_id': null,
          });
          _logSupabase('Response received', 'auction_state.upsert success auctionId=${auction.id}');
        }

        if (mounted) {
          AppToast.showSuccess(
            context,
            'Auction "${auction.name}" is now Live!',
          );
          _logAuction('Go Live success', 'auctionId=${auction.id}');

          // Refresh so the button changes from Go Live to Stop immediately
          await _handleRefresh();
          _logAuction('Refresh triggered', 'auctionId=${auction.id}');
        }
      } catch (e, st) {
        _logError('Go Live failed', e, st);
        if (mounted) {
          AppToast.showError(context, 'Failed to go live: $e');
        }
      }
    });
  }

  // ============ AUCTION ACTION BUTTON ============
  Widget _buildAuctionActionButton(Auction auction) {
    final isLoading = _isProcessing(auction.id);
    switch (auction.status) {
      case AuctionStatus.draft:
        return GradientButton(
          height: 40,
          onPressed: isLoading
              ? null
              : () => _withProcessing(auction.id, () => _handleGoLive(auction)),
          icon: Icons.gavel_rounded,
          label: 'Go Live',
          width: double.infinity,
          isLoading: isLoading,
        );
      case AuctionStatus.live:
        return GradientButton(
          height: 40,
          onPressed: isLoading
              ? null
              : () => _withProcessing(auction.id, () => _handleStopAuction(auction)),
          icon: Icons.pause_rounded,
          label: 'Stop',
          width: double.infinity,
          gradient: const LinearGradient(
            colors: [AppColors.warning, AppColors.warning],
          ),
          isLoading: isLoading,
        );
      case AuctionStatus.paused:
        return GradientButton(
          height: 40,
          onPressed: isLoading
              ? null
              : () => _withProcessing(auction.id, () => _handleResumeAuction(auction)),
          icon: Icons.play_circle_rounded,
          label: 'Resume',
          width: double.infinity,
          gradient: const LinearGradient(
            colors: [AppColors.statusLive, AppColors.statusLive],
          ),
          isLoading: isLoading,
        );
      case AuctionStatus.completed:
        return GradientButton(
          height: 40,
          onPressed: isLoading
              ? null
              : () => _withProcessing(
                  auction.id, () => _handleRestartAuction(auction)),
          icon: Icons.restart_alt_rounded,
          label: 'Restart',
          width: double.infinity,
          gradient: const LinearGradient(
            colors: [AppColors.secondaryPurple, AppColors.secondaryPurple],
          ),
          isLoading: isLoading,
        );
      case AuctionStatus.archived:
        return const SizedBox.shrink();
    }
  }

  // ============ STOP AUCTION ============
  Future<void> _handleStopAuction(Auction auction) async {
    _logAuction('Stop clicked', 'auctionId=${auction.id}, name="${auction.name}"');

    final confirm = await AppConfirmDialog.show(
      context,
      title: 'Stop Auction?',
      content:
          'Are you sure you want to stop/pause the auction "${auction.name}"? The auction will be paused and removed from active controls.',
      confirmText: 'Stop',
      isDestructive: false,
    );
    if (confirm != true) {
      _logAuction('Stop cancelled', 'auctionId=${auction.id}');
      return;
    }

    await _withProcessing(auction.id, () async {
      try {
        _logSupabase('Request started', 'pause_auction RPC auctionId=${auction.id}');

        await ref.read(liveAuctionClientProvider).pauseAuction(
          auctionId: auction.id,
        );

        _logSupabase('Response received', 'pause_auction success auctionId=${auction.id}');

        // Also update auctions.status to 'paused' so the button changes to Resume immediately
        final updated = auction.copyWith(status: AuctionStatus.paused);
        await ref.read(auctionRepositoryProvider).save(updated);

        _logSupabase('Response received', 'auctions.upsert status=paused auctionId=${auction.id}');

        if (mounted) {
          AppToast.showSuccess(context, 'Auction "${auction.name}" paused.');
          _logAuction('Stop success', 'auctionId=${auction.id}');

          await _handleRefresh();
          _logAuction('Refresh triggered', 'auctionId=${auction.id}');
        }
      } catch (e, st) {
        _logError('Stop failed', e, st);
        if (mounted) {
          AppToast.showError(context, 'Failed to pause: $e');
        }
      }
    });
  }

  // ============ RESUME AUCTION ============
  Future<void> _handleResumeAuction(Auction auction) async {
    _logAuction('Resume clicked', 'auctionId=${auction.id}, name="${auction.name}"');

    final confirm = await AppConfirmDialog.show(
      context,
      title: 'Resume Auction?',
      content:
          'Are you sure you want to resume the auction "${auction.name}"? Bidding will continue from where it stopped.',
      confirmText: 'Resume',
    );
    if (confirm != true) {
      _logAuction('Resume cancelled', 'auctionId=${auction.id}');
      return;
    }

    await _withProcessing(auction.id, () async {
      try {
        _logSupabase('Request started', 'resume_auction RPC auctionId=${auction.id}');

        await ref.read(liveAuctionClientProvider).resumeAuction(
          auctionId: auction.id,
        );

        _logSupabase('Response received', 'resume_auction success auctionId=${auction.id}');

        // Also update auctions.status to 'live' so the button changes to Stop immediately
        final updated = auction.copyWith(status: AuctionStatus.live);
        await ref.read(auctionRepositoryProvider).save(updated);

        _logSupabase('Response received', 'auctions.upsert status=live auctionId=${auction.id}');

        if (mounted) {
          AppToast.showSuccess(context, 'Auction "${auction.name}" resumed.');
          _logAuction('Resume success', 'auctionId=${auction.id}');

          await _handleRefresh();
          _logAuction('Refresh triggered', 'auctionId=${auction.id}');
        }
      } catch (e, st) {
        _logError('Resume failed', e, st);
        if (mounted) {
          AppToast.showError(context, 'Failed to resume: $e');
        }
      }
    });
  }

  // ============ RESTART AUCTION ============
  Future<void> _handleRestartAuction(Auction auction) async {
    _logAuction('Restart clicked', 'auctionId=${auction.id}, name="${auction.name}"');

    final confirm = await AppConfirmDialog.show(
      context,
      title: 'Restart Auction?',
      content:
          'Are you sure you want to restart the auction "${auction.name}"? All bids will be cleared and players will be reset to available. Previous results are preserved in the activity log.',
      confirmText: 'Restart',
      isDestructive: false,
    );
    if (confirm != true) {
      _logAuction('Restart cancelled', 'auctionId=${auction.id}');
      return;
    }

    await _withProcessing(auction.id, () async {
      try {
        _logSupabase('Request started', 'restart_auction RPC auctionId=${auction.id}');

        await ref.read(liveAuctionClientProvider).restartAuction(
          auctionId: auction.id,
        );

        _logSupabase('Response received', 'restart_auction success auctionId=${auction.id}');

        if (mounted) {
          AppToast.showSuccess(context, 'Auction "${auction.name}" restarted.');
          _logAuction('Restart success', 'auctionId=${auction.id}');

          await _handleRefresh();
          _logAuction('Refresh triggered', 'auctionId=${auction.id}');
        }
      } catch (e, st) {
        _logError('Restart failed', e, st);
        if (mounted) {
          AppToast.showError(context, 'Failed to restart: $e');
        }
      }
    });
  }

  // ============ END AUCTION ============
  Future<void> _handleEndAuction(Auction auction) async {
    _logAuction('End clicked', 'auctionId=${auction.id}, name="${auction.name}"');

    final confirm = await AppConfirmDialog.show(
      context,
      title: 'End Auction?',
      content:
          'Are you sure you want to end the auction "${auction.name}" permanently? No further bidding will be possible.',
      confirmText: 'End',
      isDestructive: true,
    );
    if (confirm != true) {
      _logAuction('End cancelled', 'auctionId=${auction.id}');
      return;
    }

    await _withProcessing(auction.id, () async {
      try {
        _logSupabase('Request started', 'complete_auction RPC auctionId=${auction.id}');

        await ref.read(liveAuctionClientProvider).completeAuction(
          auctionId: auction.id,
        );

        _logSupabase('Response received', 'complete_auction success auctionId=${auction.id}');

        if (mounted) {
          AppToast.showSuccess(context, 'Auction "${auction.name}" ended.');
          _logAuction('End success', 'auctionId=${auction.id}');

          await _handleRefresh();
          _logAuction('Refresh triggered', 'auctionId=${auction.id}');
        }
      } catch (e, st) {
        _logError('End failed', e, st);
        if (mounted) {
          AppToast.showError(context, 'Failed to end: $e');
        }
      }
    });
  }

  // ============ EMPTY STATE ============
  Widget _buildEmptyState({
    required String title,
    required String subtitle,
    required String buttonLabel,
    VoidCallback? onButtonPressed,
  }) {
    return GlassCard(
      padding: const EdgeInsets.symmetric(vertical: 56, horizontal: 32),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 120,
                height: 120,
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
                  border: Border.all(color: AppColors.cardBorder, width: 2),
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
                    size: 56,
                    color: AppColors.gold,
                  ),
                ),
              ),
              const SizedBox(height: 26),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.3,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 28),
              GradientButton(
                onPressed:
                    onButtonPressed ??
                    () => context.go(RouteNames.createAuctionPath),
                icon: Icons.add_rounded,
                label: buttonLabel,
                width: 180,
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
