import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jp_auction_arena/core/constants/app_colors.dart';
import 'package:jp_auction_arena/core/utils/currency_formatter.dart';
import 'package:jp_auction_arena/core/theme/app_theme.dart';
import 'package:jp_auction_arena/core/widgets/glass_card.dart';
import 'package:jp_auction_arena/core/widgets/gradient_button.dart';
import 'package:jp_auction_arena/data/models/models.dart';
import 'package:jp_auction_arena/data/repositories/repositories.dart';
import 'package:jp_auction_arena/features/players/player_import_dialog.dart';
import 'package:jp_auction_arena/features/players/player_profile_dialog.dart';
import 'package:jp_auction_arena/features/players/player_registration_form.dart';
import 'package:jp_auction_arena/shared/widgets/app_text_field.dart';
import 'package:jp_auction_arena/shared/widgets/app_ui_feedback.dart';

class PlayersRefreshNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void setRefreshing(bool value) {
    state = value;
  }
}

final playersRefreshProvider = NotifierProvider<PlayersRefreshNotifier, bool>(
  PlayersRefreshNotifier.new,
);

class PlayerFilterNotifier extends Notifier<PlayerFilterState> {
  @override
  PlayerFilterState build() => const PlayerFilterState();

  void setSearch(String query) {
    state = state.copyWith(search: query);
  }

  void setStatus(PlayerStatus? status) {
    state = state.copyWith(status: status);
  }

  void setCategory(String? category) {
    state = state.copyWith(category: category);
  }

  void clearFilters() {
    state = const PlayerFilterState();
  }
}

class PlayerFilterState {
  final String search;
  final PlayerStatus? status;
  final String? category;

  const PlayerFilterState({
    this.search = '',
    this.status,
    this.category,
  });

  PlayerFilterState copyWith({
    String? search,
    PlayerStatus? status,
    String? category,
  }) {
    return PlayerFilterState(
      search: search ?? this.search,
      status: status ?? this.status,
      category: category ?? this.category,
    );
  }
}

final playerFilterProvider =
    NotifierProvider<PlayerFilterNotifier, PlayerFilterState>(
  PlayerFilterNotifier.new,
);

class PlayersScreen extends ConsumerWidget {
  const PlayersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeAuction = ref.watch(activeAuctionProvider);
    final playersAsync = ref.watch(currentAuctionPlayersProvider);
    final isRefreshing = ref.watch(playersRefreshProvider);
    final filter = ref.watch(playerFilterProvider);
    final searchQuery = filter.search.toLowerCase();
    final statusFilter = filter.status;
    final categoryFilter = filter.category;

    Future<void> handlePlayersRefresh() async {
      if (isRefreshing) return;
      ref.read(playersRefreshProvider.notifier).setRefreshing(true);
      try {
        ref.invalidate(currentAuctionPlayersProvider);
        await ref.read(currentAuctionPlayersProvider.future);
        if (context.mounted) {
          AppToast.showSuccess(context, 'Player list refreshed.');
        }
      } catch (e) {
        if (context.mounted) {
          AppToast.showError(context, 'Refresh failed: $e');
        }
      } finally {
        if (context.mounted) {
          ref.read(playersRefreshProvider.notifier).setRefreshing(false);
        }
      }
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GlassCard(
            margin: const EdgeInsets.only(bottom: 16),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          gradient: AppColors.accentGradient,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.person_search_rounded,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Player Pool',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              activeAuction != null
                                  ? 'Players for "${activeAuction.name}"'
                                  : 'Select an auction to view players',
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          GradientButton(
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (_) => const PlayerRegistrationForm(),
                              );
                            },
                            icon: Icons.person_add_rounded,
                            label: 'Add Player',
                            width: 120,
                          ),
                          const SizedBox(height: 8),
                          GradientButton(
                            onPressed: handlePlayersRefresh,
                            icon: Icons.refresh_rounded,
                            label: 'Refresh',
                            width: 110,
                            isLoading: isRefreshing,
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  AppTextField(
                    label: 'Search players',
                    hintText: 'Search by name, mobile, village...',
                    prefixIcon: const Icon(
                      Icons.search_rounded,
                      color: AppColors.textSecondary,
                      size: 18,
                    ),
                    onChanged: (v) =>
                        ref.read(playerFilterProvider.notifier).setSearch(v),
                  ),
                  const SizedBox(height: 12),

                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      FilterChip(
                        label: const Text('All'),
                        selected: statusFilter == null && categoryFilter == null,
                        onSelected: (_) {
                          ref.read(playerFilterProvider.notifier).clearFilters();
                        },
                        backgroundColor: AppColors.surfaceLight,
                        selectedColor:
                            AppColors.primaryBlue.withValues(alpha: 0.2),
                        checkmarkColor: AppColors.primaryBlue,
                      ),
                      ...PlayerStatus.values.map((status) {
                        return FilterChip(
                          label: Text(status.displayName),
                          selected: statusFilter == status,
                          onSelected: (sel) {
                            ref
                                .read(playerFilterProvider.notifier)
                                .setStatus(sel ? status : null);
                            ref
                                .read(playerFilterProvider.notifier)
                                .setCategory(null);
                          },
                          backgroundColor: AppColors.surfaceLight,
                          selectedColor: _statusColor(status)
                              .withValues(alpha: 0.2),
                          checkmarkColor: _statusColor(status),
                        );
                      }),
                      ...['Batsman', 'Bowler', 'All-Rounder', 'Wicket-Keeper']
                          .map((cat) {
                        return FilterChip(
                          label: Text(cat),
                          selected: categoryFilter == cat,
                          onSelected: (sel) {
                            ref
                                .read(playerFilterProvider.notifier)
                                .setCategory(sel ? cat : null);
                            ref
                                .read(playerFilterProvider.notifier)
                                .setStatus(null);
                          },
                          backgroundColor: AppColors.surfaceLight,
                          selectedColor:
                              AppColors.accentPink.withValues(alpha: 0.2),
                          checkmarkColor: AppColors.accentPink,
                        );
                      }),
                      const SizedBox(width: 8),
                      GradientButton(
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (_) => const PlayerImportDialog(),
                          );
                        },
                        icon: Icons.import_contacts_rounded,
                        label: 'Import CSV',
                        width: 100,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          playersAsync.when(
            data: (allPlayers) {
              final filtered = allPlayers.where((p) {
                final matchesSearch = p.name.toLowerCase().contains(searchQuery) ||
                    (p.mobile ?? '').toLowerCase().contains(searchQuery) ||
                    p.village.toLowerCase().contains(searchQuery);
                final matchesStatus = statusFilter == null || p.status == statusFilter;
                final matchesCategory = categoryFilter == null || p.category == categoryFilter;
                return matchesSearch && matchesStatus && matchesCategory;
              }).toList()
                ..sort((a, b) => a.playerNo.compareTo(b.playerNo));

              if (filtered.isEmpty) {
                return GlassCard(
                  padding: const EdgeInsets.all(40),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.search_off_rounded,
                        size: 54,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        searchQuery.isNotEmpty ||
                                statusFilter != null ||
                                categoryFilter != null
                            ? 'No Players Match Filter'
                            : 'No Players Registered',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        searchQuery.isNotEmpty ||
                                statusFilter != null ||
                                categoryFilter != null
                            ? 'Try adjusting your search or filters.'
                            : "Register cricketers to build the auction pool.",
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 20),
                      GradientButton(
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (_) => const PlayerRegistrationForm(),
                          );
                        },
                        icon: Icons.person_add_rounded,
                        label: 'Add First Player',
                      ),
                    ],
                  ),
                );
              }

              return Column(
                children: List.generate(filtered.length, (index) {
                  final p = filtered[index];
                  Color badgeColor = _statusColor(p.status);

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: GlassCard(
                      margin: const EdgeInsets.symmetric(horizontal: 0),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
                        onTap: () {
                          showDialog(
                            context: context,
                            builder: (_) => PlayerProfileDialog(player: p),
                          );
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          child: Row(
                            children: [
                              Hero(
                                tag: 'player_photo_${p.id}',
                                child: CircleAvatar(
                                  radius: 22,
                                  backgroundColor: AppColors.surfaceLight,
                                  backgroundImage: p.photoBase64 != null
                                      ? NetworkImage(p.photoBase64!)
                                      : null,
                                  child: p.photoBase64 == null
                                      ? Text(
                                          '#${p.playerNo}',
                                          style: const TextStyle(
                                            color: AppColors.accentPink,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                          ),
                                        )
                                      : null,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Wrap(
                                      spacing: 8,
                                      crossAxisAlignment:
                                          WrapCrossAlignment.center,
                                      children: [
                                        Text(
                                          p.name,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 15,
                                            fontWeight: FontWeight.w600,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        if (p.isIcon)
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 6,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: AppColors.gold
                                                  .withValues(alpha: 0.2),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: const Text(
                                              'ICON',
                                              style: TextStyle(
                                                color: AppColors.gold,
                                                fontSize: 8,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${p.category} • ${p.battingStyle} • ${p.village.isNotEmpty ? p.village : "Local"}',
                                      style: const TextStyle(
                                        color: AppColors.textSecondary,
                                        fontSize: 12,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                formatShort(p.basePrice),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: badgeColor.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  p.status.displayName,
                                  style: TextStyle(
                                    color: badgeColor,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  IconButton(
                                    icon: const Icon(
                                      Icons.edit_outlined,
                                      color: AppColors.primaryBlue,
                                      size: 16,
                                    ),
                                    onPressed: () {
                                      showDialog(
                                        context: context,
                                        builder: (_) => PlayerRegistrationForm(
                                          playerToEdit: p,
                                          onSaved: () {},
                                        ),
                                      );
                                    },
                                    constraints: const BoxConstraints(),
                                    padding: const EdgeInsets.all(2),
                                    tooltip: 'Edit',
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.delete_outline,
                                      color: AppColors.error,
                                      size: 16,
                                    ),
                                    onPressed: () async {
                                      final confirm = await AppConfirmDialog.show(
                                        context,
                                        title: 'Delete Player',
                                        content:
                                            'Are you sure you want to remove "${p.name}" (#${p.playerNo})?',
                                        confirmText: 'Delete',
                                        isDestructive: true,
                                      );
                                      if (confirm == true && context.mounted) {
                                        await ref
                                            .read(playerRepositoryProvider)
                                            .delete(p.id);
                                        if (context.mounted) {
                                          AppToast.showSuccess(
                                            context,
                                            'Player "${p.name}" deleted.',
                                          );
                                        }
                                      }
                                    },
                                    constraints: const BoxConstraints(),
                                    padding: const EdgeInsets.all(2),
                                    tooltip: 'Delete',
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              );
            },
            loading: () => Column(
              children: List.generate(
                4,
                (i) => const Padding(
                  padding: EdgeInsets.only(bottom: 12),
                  child: AppSkeleton.card(height: 72),
                ),
              ),
            ),
            error: (e, _) => AppEmptyState(
              icon: Icons.error_outline_rounded,
              title: 'Unable to Load Players',
              description: e.toString(),
              action: GradientButton(
                onPressed: handlePlayersRefresh,
                icon: Icons.refresh_rounded,
                label: 'Retry',
                width: 120,
                isLoading: isRefreshing,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _statusColor(PlayerStatus status) {
    switch (status) {
      case PlayerStatus.available:
        return AppColors.primaryBlue;
      case PlayerStatus.sold:
        return AppColors.success;
      case PlayerStatus.unsold:
        return AppColors.textMuted;
      case PlayerStatus.live:
        return AppColors.error;
    }
  }
}
