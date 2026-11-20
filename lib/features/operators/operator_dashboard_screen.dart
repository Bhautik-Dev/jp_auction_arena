import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../core/routing/route_names.dart';
import '../../core/supabase/supabase_client.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/gradient_button.dart';
import '../../data/models/models.dart';
import '../../data/repositories/repositories.dart';
import '../../shared/widgets/app_ui_feedback.dart';

class OperatorDashboardScreen extends ConsumerStatefulWidget {
  const OperatorDashboardScreen({super.key});

  @override
  ConsumerState<OperatorDashboardScreen> createState() =>
      _OperatorDashboardScreenState();
}

class _OperatorDashboardScreenState
    extends ConsumerState<OperatorDashboardScreen> {
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
  }

  Future<void> _refresh() async {
    setState(() => _isRefreshing = true);
    // StreamBuilder will auto-refresh on rebuild
    if (mounted) setState(() => _isRefreshing = false);
  }

  Future<void> _takeControl(String auctionId, String auctionName) async {
    final client = SupabaseClientService.instance.client;
    if (client == null) {
      if (mounted) {
        AppToast.showError(context, 'Supabase not connected.');
      }
      return;
    }

    final userId = client.auth.currentUser?.id;
    if (userId == null) {
      if (mounted) {
        AppToast.showError(context, 'Authentication required.');
      }
      return;
    }

    try {
      // Claim control via RPC (validates operator permission server-side)
      final result = await client.rpc('claim_auction_control', params: {
        'auction_id': auctionId,
        'operator_id': userId.toString(),
      }).single();

      final success = result['success'] as bool? ?? false;
      final errorMessage = result['error_message'] as String?;

      if (!success) {
        if (mounted) {
          AppToast.showError(context, errorMessage ?? 'Failed to take control');
        }
        return;
      }

      if (mounted) {
        AppToast.showSuccess(
          context,
          'You are now controlling "$auctionName".',
        );
        ref.read(activeAuctionIdProvider.notifier).setAuctionId(auctionId);
        context.go(RouteNames.liveAuctionPath.replaceAll(':auctionId', auctionId));
      }
    } catch (e) {
      if (mounted) {
        AppToast.showError(context, 'Failed to take control: $e');
      }
    }
  }

  Widget _buildControlStatus(Map<String, dynamic> state) {
    final controllingOpId = state['controlling_operator_id'] as String?;
    final isLive = state['is_live'] as bool? ?? false;
    final client = SupabaseClientService.instance.client;
    final currentUser = client!.auth.currentUser;
    final currentUserId = currentUser?.id.toString();

    if (!isLive) {
      return const Text(
        'Not Live',
        style: TextStyle(color: AppColors.textMuted, fontSize: 11),
      );
    }

    if (controllingOpId == null || controllingOpId.isEmpty) {
      return Text(
        'Available',
        style: TextStyle(
          color: AppColors.success,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      );
    }

    if (controllingOpId == currentUserId) {
      return Text(
        'You Control',
        style: TextStyle(
          color: AppColors.primaryBlue,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      );
    }

    return Text(
      'In Use',
      style: TextStyle(
        color: AppColors.warning,
        fontSize: 11,
        fontWeight: FontWeight.w700,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final client = SupabaseClientService.instance.client;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Operator Dashboard'),
        backgroundColor: AppColors.card,
        elevation: 0,
        centerTitle: true,
        actions: [
          GradientButton(
            onPressed: _isRefreshing ? null : _refresh,
            icon: Icons.refresh_rounded,
            label: 'Refresh',
            width: 100,
            isLoading: _isRefreshing,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: client == null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.cloud_off_rounded,
                    size: 64,
                    color: AppColors.textMuted,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Supabase Not Connected',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Please initialize Supabase and restart the app.',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 20),
                  GradientButton(
                    onPressed: _refresh,
                    icon: Icons.refresh_rounded,
                    label: 'Retry',
                    width: 140,
                  ),
                ],
              ),
            )
          : StreamBuilder<List<Map<String, dynamic>>>(
              stream: client
                  .from('auctions')
                  .stream(primaryKey: ['id'])
                  .eq('status', 'live')
                  .order('created_at', ascending: false),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  final error = snapshot.error.toString();
                  final isRealtimeError = error.contains('Realtime') ||
                      error.contains('channelError') ||
                      error.contains('supabase_realtime');
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.error_outline_rounded,
                          size: 64,
                          color: AppColors.error,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          isRealtimeError
                              ? 'Live feed unavailable'
                              : 'Failed to load live auctions',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          isRealtimeError
                              ? 'Realtime is not enabled for the auctions table. '
                                  'Ask your administrator to run the Realtime migration.'
                              : error,
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 20),
                        GradientButton(
                          onPressed: _refresh,
                          icon: Icons.refresh_rounded,
                          label: 'Retry',
                          width: 140,
                        ),
                      ],
                    ),
                  );
                }

                final auctions = snapshot.data ?? [];

                if (snapshot.connectionState == ConnectionState.waiting &&
                    auctions.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        AppSkeleton.card(height: 100),
                        SizedBox(height: 16),
                        AppSkeleton.card(height: 100),
                        SizedBox(height: 16),
                        AppSkeleton.card(height: 100),
                      ],
                    ),
                  );
                }

                if (auctions.isEmpty) {
                  return AppEmptyState(
                    icon: Icons.gavel_rounded,
                    title: 'No Live Auctions',
                    description:
                        'No auctions are currently live. Ask an admin to go live from the Auctions screen.',
                    action: GradientButton(
                      onPressed: () => context.go('/auctions'),
                      icon: Icons.emoji_events_rounded,
                      label: 'Go to Auctions',
                      width: 180,
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: auctions.length,
                  itemBuilder: (context, index) {
                    final row = auctions[index];
                    final auction = Auction.fromMap({
                      'id': row['id'],
                      'name': row['name'],
                      'logoBase64': row['logo_base64'],
                      'venue': row['venue'],
                      'description': row['description'],
                      'startDateTime': row['start_date_time'],
                      'status': row['status'],
                      'categories': row['categories'],
                      'numberOfTeams': row['number_of_teams'],
                      'minSquad': row['min_squad'],
                      'maxSquad': row['max_squad'],
                      'basePriceDefault': row['base_price_default'],
                      'bidIncrement': row['bid_increment'],
                      'teamPurse': row['team_purse'],
                      'countdownSeconds': row['countdown_seconds'],
                      'mode': row['mode'],
                      'createdAt': row['created_at'],
                      'contactPhone': row['contact_phone'],
                      'contactEmail': row['contact_email'],
                      'categoryBasePrices': row['category_base_prices'],
                      'reservePurseRule': row['reserve_purse_rule'],
                      'smartBidSlabs': row['smart_bid_slabs'],
                    });

                    return FutureBuilder<List<Team>>(
                      future:
                          ref.read(teamRepositoryProvider).getByAuctionId(
                                auction.id,
                              ),
                      builder: (ctx, teamsSnap) {
                        final teams = teamsSnap.data ?? [];
                        return FutureBuilder<List<Player>>(
                          future: ref
                              .read(playerRepositoryProvider)
                              .getByAuctionId(auction.id),
                          builder: (ctx, playersSnap) {
                            final players = playersSnap.data ?? [];
                            final soldCount =
                                players.where((p) => p.status == PlayerStatus.sold).length;
                            final availableCount = players.where(
                              (p) => p.status == PlayerStatus.available,
                            ).length;

                            // Fetch auction state for control status
                            return FutureBuilder<Map<String, dynamic>?>(
                              future: client
                                  .from('auction_state')
                                  .select()
                                  .eq('auction_id', auction.id)
                                  .maybeSingle(),
                              builder: (ctx, stateSnap) {
                                final state = stateSnap.data ?? {};
                                final isControlling =
                                    state['controlling_operator_id'] ==
                                        client.auth.currentUser?.id.toString() ||
                                        state['controlling_operator_id'] ==
                                            null;

                                return GlassCard(
                                  margin: const EdgeInsets.only(bottom: 10),
                                  child: Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                            Row(
                                              children: [
                                                _buildAuctionLogo(auction),
                                                const SizedBox(width: 8),
                                                _buildPendingBadge('Pending API'),
                                                const SizedBox(width: 8),
                                                Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Row(
                                                    children: [
                                                      Expanded(
                                                        child: Text(
                                                          auction.name,
                                                          style: const TextStyle(
                                                            color: Colors.white,
                                                            fontSize: 15,
                                                            fontWeight:
                                                                FontWeight.w800,
                                                          ),
                                                        ),
                                                      ),
                                                      Container(
                                                        padding: const EdgeInsets
                                                            .symmetric(
                                                          horizontal: 10,
                                                          vertical: 3,
                                                        ),
                                                        decoration: BoxDecoration(
                                                          color: AppColors
                                                              .statusLive
                                                              .withValues(
                                                                alpha: 0.2,
                                                              ),
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(8),
                                                          border: Border.all(
                                                              color: AppColors
                                                                  .statusLive),
                                                        ),
                                                        child: const Text(
                                                          'LIVE',
                                                          style: TextStyle(
                                                            color:
                                                                AppColors
                                                                    .statusLive,
                                                            fontSize: 9,
                                                            fontWeight:
                                                                FontWeight
                                                                    .w900,
                                                            letterSpacing:
                                                                0.5,
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  const SizedBox(height: 6),
                                                  Row(
                                                    children: [
                                                      const Icon(
                                                        Icons
                                                            .location_on_outlined,
                                                        size: 11,
                                                        color: AppColors
                                                            .textMuted,
                                                      ),
                                                      const SizedBox(width: 4),
                                                      Expanded(
                                                        child: Text(
                                                          auction
                                                              .venue.isNotEmpty
                                                              ? auction
                                                                  .venue
                                                              : 'Venue Not Specified',
                                                          style: const TextStyle(
                                                            color: AppColors
                                                                .textSecondary,
                                                            fontSize: 11,
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  const SizedBox(height: 12),
                                                  Row(
                                                    children: [
                                                      _buildStatChip(
                                                        'Teams',
                                                        teams.length
                                                            .toString(),
                                                        Icons.groups_rounded,
                                                        AppColors.primaryBlue,
                                                      ),
                                                      _buildStatChip(
                                                        'Players',
                                                        players.length
                                                            .toString(),
                                                        Icons.person_rounded,
                                                        AppColors.secondaryPurple,
                                                      ),
                                                      _buildStatChip(
                                                        'Sold',
                                                        soldCount.toString(),
                                                        Icons.how_to_reg_rounded,
                                                        AppColors.statusSold,
                                                      ),
                                                      _buildStatChip(
                                                        'Available',
                                                        availableCount
                                                            .toString(),
                                                        Icons.thumb_up_rounded,
                                                        AppColors.statusAvailable,
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.end,
                                              children: [
                                                _buildControlStatus(state),
                                                const SizedBox(height: 8),
                                                GradientButton(
                                                  height: 36,
                                                  onPressed:
                                                      isControlling
                                                          ? () =>
                                                              _takeControl(
                                                            auction.id,
                                                            auction.name,
                                                          )
                                                          : null,
                                                  icon: Icons
                                                      .supervised_user_circle_rounded,
                                                  label: 'Control',
                                                  width: double.infinity,
                                                  isLoading: false,
                                                ),
                                                const SizedBox(height: 8),
                                                _buildPendingBadge('Pending API'),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  )
                                ;
                              },
                            );
                          },
                        );
                      },
                    );
                  },
                );
              },
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
            width: 36,
            height: 36,
            fit: BoxFit.cover,
          ),
        );
      } catch (_) {}
    }

    return Container(
      width: 36,
      height: 36,
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

  Widget _buildStatChip(
    String label,
    String value,
    IconData icon,
    Color color, {
    bool isCompact = false,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 8 : 10,
        vertical: isCompact ? 6 : 8,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(isCompact ? 8 : 10),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: isCompact ? 10 : 12, color: color),
          const SizedBox(width: 3),
          Text(
            value,
            style: TextStyle(
              color: Colors.white,
              fontSize: isCompact ? 10 : 12,
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

  Widget _buildPendingBadge(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.warning),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.pending_actions_rounded,
            size: 10,
            color: AppColors.warning,
          ),
          const SizedBox(width: 4),
          Text(
            text,
            style: const TextStyle(
              color: AppColors.warning,
              fontSize: 9,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}
