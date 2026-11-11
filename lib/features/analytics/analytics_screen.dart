import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_colors.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/widgets/glass_card.dart';
import '../../data/models/models.dart';
import '../../data/repositories/repositories.dart';

class AnalyticsScreen extends ConsumerStatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  ConsumerState<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends ConsumerState<AnalyticsScreen> {
  final GlobalKey _repaintBoundaryKey = GlobalKey();
  bool _isExporting = false;
  int? _touchedPieIndex;
  String? _selectedTeamForDonut;

  // Consistent color palette for teams & categories
  static const List<Color> _chartPalette = [
    AppColors.primaryBlue,
    AppColors.secondaryPurple,
    AppColors.accentPink,
    AppColors.gold,
    AppColors.success,
    AppColors.info,
    Color(0xFFFF7A00),
    Color(0xFFE040FB),
    Color(0xFF00E5FF),
    Color(0xFFFF5252),
    Color(0xFF76FF03),
    Color(0xFFFFD600),
  ];

  Color _colorForIndex(int index) => _chartPalette[index % _chartPalette.length];

  Future<void> _exportAsImage() async {
    setState(() => _isExporting = true);
    try {
      await Future.delayed(const Duration(milliseconds: 100));
      final boundary = _repaintBoundaryKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) throw Exception('Boundary not found');

      final image = await boundary.toImage(pixelRatio: 2.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final bytes = byteData?.buffer.asUint8List();

      if (!mounted) return;
      if (bytes != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.card,
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: AppColors.success),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Analytics snapshot captured successfully (${(bytes.lengthInBytes / 1024).toStringAsFixed(1)} KB PNG ready).',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.error,
          content: Text('Failed to export snapshot: $e'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  void _showExportOptions(BuildContext context, String auctionName, List<Player> players, List<Team> teams, List<Bid> bids) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.secondaryPurple.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.download_rounded, color: AppColors.secondaryPurple, size: 22),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Export Analytics Report',
                      style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Material(
                  color: AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(12),
                  child: ListTile(
                    leading: const Icon(Icons.image_rounded, color: AppColors.primaryBlue),
                    title: const Text('Export as High-Res Image (PNG)', style: TextStyle(color: Colors.white)),
                    subtitle: const Text('Render current dashboard with all charts', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    onTap: () {
                      Navigator.pop(ctx);
                      _exportAsImage();
                    },
                  ),
                ),
                const SizedBox(height: 10),
                Material(
                  color: AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(12),
                  child: ListTile(
                    leading: const Icon(Icons.picture_as_pdf_rounded, color: AppColors.accentPink),
                    title: const Text('Export Analytics Summary (PDF / Report Text)', style: TextStyle(color: Colors.white)),
                    subtitle: const Text('Generate printable metrics document', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    onTap: () {
                      Navigator.pop(ctx);
                      _exportSummaryReport(auctionName, players, teams, bids);
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _exportSummaryReport(String auctionName, List<Player> players, List<Team> teams, List<Bid> bids) {
    final soldPlayers = players.where((p) => p.status == PlayerStatus.sold).toList();
    final totalSpent = soldPlayers.fold<double>(0.0, (acc, p) => acc + (p.soldPrice ?? 0.0));
    final avgPrice = soldPlayers.isNotEmpty ? totalSpent / soldPlayers.length : 0.0;
    final highestBid = soldPlayers.isNotEmpty ? soldPlayers.map((p) => p.soldPrice ?? 0.0).reduce(math.max) : 0.0;
    final lowestBid = soldPlayers.isNotEmpty ? soldPlayers.map((p) => p.soldPrice ?? 0.0).reduce(math.min) : 0.0;

    final report = StringBuffer();
    report.writeln('==============================================');
    report.writeln('  JP AUCTION ARENA - ANALYTICS REPORT');
    report.writeln('  Auction: $auctionName');
    report.writeln('  Generated: ${DateTime.now().toLocal().toString().split('.')[0]}');
    report.writeln('==============================================\n');
    report.writeln('KEY METRICS:');
    report.writeln('- Total Auction Value: ${CurrencyFormatter.formatInr(totalSpent)} (${CurrencyFormatter.formatShort(totalSpent)})');
    report.writeln('- Average Player Price: ${CurrencyFormatter.formatInr(avgPrice)}');
    report.writeln('- Highest Bid: ${CurrencyFormatter.formatInr(highestBid)}');
    report.writeln('- Lowest Bid: ${CurrencyFormatter.formatInr(lowestBid)}');
    report.writeln('- Total Bids Placed: ${bids.length}');
    report.writeln('- Clearance: ${soldPlayers.length}/${players.length} players sold\n');

    report.writeln('TEAM EXPENDITURES:');
    for (final t in teams) {
      report.writeln('- ${t.name}: Spent ${CurrencyFormatter.formatInr(t.purseSpent)} / Remaining ${CurrencyFormatter.formatInr(t.purseRemaining)} (${t.squadCount} players)');
    }

    Clipboard.setData(ClipboardData(text: report.toString()));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.card,
        content: const Row(
          children: [
            Icon(Icons.description_rounded, color: AppColors.accentPink),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Full printable Analytics Summary copied to clipboard (ready for PDF/Print document).',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final allAuctions = ref.watch(auctionsListProvider).value ?? [];
    final activeAuction = ref.watch(activeAuctionProvider);
    final players = ref.watch(currentAuctionPlayersProvider).value ?? [];
    final teams = ref.watch(currentAuctionTeamsProvider).value ?? [];
    final bids = ref.watch(currentAuctionBidsProvider).value ?? [];

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTopControlBar(allAuctions, activeAuction, players, teams, bids),
            const SizedBox(height: 20),
            RepaintBoundary(
              key: _repaintBoundaryKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildKpiCards(players, bids),
                  const SizedBox(height: 24),
                  _buildFirstChartsRow(teams, players),
                  const SizedBox(height: 24),
                  _buildSecondChartsRow(bids, teams),
                  const SizedBox(height: 24),
                  _buildNewInsightsSection(players, bids, teams),
                  const SizedBox(height: 24),
                  _buildScatterSection(players),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // TOP CONTROL BAR: Dropdown, Refresh, Export
  // ==========================================
  Widget _buildTopControlBar(
    List<Auction> allAuctions,
    Auction? activeAuction,
    List<Player> players,
    List<Team> teams,
    List<Bid> bids,
  ) {
    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 16,
        runSpacing: 12,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primaryBlue.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.primaryBlue.withValues(alpha: 0.3)),
                ),
                child: const Icon(Icons.analytics_rounded, color: AppColors.primaryBlue, size: 24),
              ),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Auction Analytics & Insights',
                    style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    activeAuction != null ? 'Data for: ${activeAuction.name}' : 'Select an auction to view metrics',
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
          Wrap(
            spacing: 12,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              // Auction dropdown filter
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    dropdownColor: AppColors.card,
                    value: activeAuction?.id,
                    hint: const Text('Select Auction', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                    icon: const Icon(Icons.arrow_drop_down, color: AppColors.primaryBlue),
                    items: allAuctions.map((a) {
                      return DropdownMenuItem<String>(
                        value: a.id,
                        child: Text(
                          a.name,
                          style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                      );
                    }).toList(),
                    onChanged: (id) {
                      if (id != null) {
                        ref.read(activeAuctionIdProvider.notifier).setAuctionId(id);
                      }
                    },
                  ),
                ),
              ),
              // Refresh button
              IconButton(
                tooltip: 'Refresh analytics',
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.surfaceLight,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                icon: const Icon(Icons.refresh_rounded, color: Colors.white, size: 20),
                onPressed: () {
                  ref.invalidate(currentAuctionPlayersProvider);
                  ref.invalidate(currentAuctionTeamsProvider);
                  ref.invalidate(currentAuctionBidsProvider);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      backgroundColor: AppColors.card,
                      content: const Text('Analytics refreshed'),
                      duration: const Duration(milliseconds: 1200),
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  );
                },
              ),
              // Export button
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryBlue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                icon: _isExporting
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.download_rounded, size: 18),
                label: const Text('Export Analytics', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                onPressed: _isExporting ? null : () => _showExportOptions(context, activeAuction?.name ?? 'Auction Arena', players, teams, bids),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ==========================================
  // CARDS: Total Auction Value, Avg Player Price,
  // Highest Bid, Lowest Bid, Total Bids, Players Sold x/y
  // ==========================================
  Widget _buildKpiCards(List<Player> players, List<Bid> bids) {
    final soldPlayers = players.where((p) => p.status == PlayerStatus.sold).toList();
    final totalSpent = soldPlayers.fold<double>(0.0, (acc, p) => acc + (p.soldPrice ?? 0.0));
    final avgSoldPrice = soldPlayers.isNotEmpty ? totalSpent / soldPlayers.length : 0.0;

    final highestBid = soldPlayers.isNotEmpty
        ? soldPlayers.map((p) => p.soldPrice ?? 0.0).reduce(math.max)
        : (bids.isNotEmpty ? bids.map((b) => b.amount).reduce(math.max) : 0.0);

    final lowestBid = soldPlayers.isNotEmpty
        ? soldPlayers.map((p) => p.soldPrice ?? 0.0).reduce(math.min)
        : (bids.isNotEmpty ? bids.map((b) => b.amount).reduce(math.min) : 0.0);

    final totalBidsCount = bids.length;
    final soldFraction = '${soldPlayers.length}/${players.length}';

    return LayoutBuilder(
      builder: (context, constraints) {
        final crossCount = constraints.maxWidth > 1100
            ? 6
            : (constraints.maxWidth > 750 ? 3 : 2);
        final itemWidth = (constraints.maxWidth - ((crossCount - 1) * 12)) / crossCount;

        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            SizedBox(
              width: itemWidth,
              child: _buildMetricCard(
                title: 'Total Auction Value',
                value: CurrencyFormatter.formatShort(totalSpent),
                subtitle: CurrencyFormatter.formatInr(totalSpent),
                accentColor: AppColors.gold,
                icon: Icons.account_balance_wallet_rounded,
              ),
            ),
            SizedBox(
              width: itemWidth,
              child: _buildMetricCard(
                title: 'Average Player Price',
                value: CurrencyFormatter.formatShort(avgSoldPrice),
                subtitle: CurrencyFormatter.formatInr(avgSoldPrice),
                accentColor: AppColors.primaryBlue,
                icon: Icons.trending_up_rounded,
              ),
            ),
            SizedBox(
              width: itemWidth,
              child: _buildMetricCard(
                title: 'Highest Bid',
                value: CurrencyFormatter.formatShort(highestBid),
                subtitle: CurrencyFormatter.formatInr(highestBid),
                accentColor: AppColors.accentPink,
                icon: Icons.military_tech_rounded,
              ),
            ),
            SizedBox(
              width: itemWidth,
              child: _buildMetricCard(
                title: 'Lowest Bid',
                value: CurrencyFormatter.formatShort(lowestBid),
                subtitle: CurrencyFormatter.formatInr(lowestBid),
                accentColor: AppColors.info,
                icon: Icons.arrow_downward_rounded,
              ),
            ),
            SizedBox(
              width: itemWidth,
              child: _buildMetricCard(
                title: 'Total Bids Placed',
                value: totalBidsCount.toString(),
                subtitle: 'Auction bid events',
                accentColor: AppColors.secondaryPurple,
                icon: Icons.gavel_rounded,
              ),
            ),
            SizedBox(
              width: itemWidth,
              child: _buildMetricCard(
                title: 'Players Sold',
                value: soldFraction,
                subtitle: players.isNotEmpty
                    ? '${((soldPlayers.length / players.length) * 100).toStringAsFixed(1)}% clearance'
                    : '0% clearance',
                accentColor: AppColors.success,
                icon: Icons.how_to_reg_rounded,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required String subtitle,
    required Color accentColor,
    required IconData icon,
  }) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: accentColor, size: 16),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(color: accentColor, fontSize: 22, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // ==========================================
  // ROW 1 CHARTS:
  // - Team Spending Comparison (horizontal bars with team colors)
  // - Category Spending (bar + count)
  // ==========================================
  Widget _buildFirstChartsRow(List<Team> teams, List<Player> players) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 880;
        final halfWidth = (constraints.maxWidth - 16) / 2;

        return isWide
            ? Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(width: halfWidth, child: _buildTeamSpendingChart(teams)),
                  const SizedBox(width: 16),
                  SizedBox(width: halfWidth, child: _buildCategorySpendingChart(players)),
                ],
              )
            : Column(
                children: [
                  _buildTeamSpendingChart(teams),
                  const SizedBox(height: 16),
                  _buildCategorySpendingChart(players),
                ],
              );
      },
    );
  }

  Widget _buildTeamSpendingChart(List<Team> teams) {
    if (teams.isEmpty) {
      return const GlassCard(
        height: 320,
        child: Center(
          child: Text('No teams registered for this auction.', style: TextStyle(color: AppColors.textSecondary)),
        ),
      );
    }

    final maxSpend = teams.fold<double>(0.0, (acc, t) => math.max(acc, t.purseSpent));
    final displayMax = maxSpend > 0 ? maxSpend : 100000.0;

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Team Spending Comparison',
                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primaryBlue.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text('${teams.length} Teams', style: const TextStyle(color: AppColors.primaryBlue, fontSize: 11)),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'Horizontal comparison of total purse utilized per team',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
          ),
          const SizedBox(height: 18),
          ...teams.asMap().entries.map((entry) {
            final idx = entry.key;
            final team = entry.value;
            final barColor = _colorForIndex(idx);
            final ratio = (team.purseSpent / displayMax).clamp(0.0, 1.0);
            final percentOfPurse = team.purseTotal > 0 ? (team.purseSpent / team.purseTotal * 100).toStringAsFixed(0) : '0';

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(color: barColor, shape: BoxShape.circle),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            team.name,
                            style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                      Text(
                        '${CurrencyFormatter.formatShort(team.purseSpent)} ($percentOfPurse% purse)',
                        style: TextStyle(color: barColor, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: Stack(
                      children: [
                        Container(height: 10, color: AppColors.surfaceLight),
                        FractionallySizedBox(
                          widthFactor: ratio,
                          child: Container(
                            height: 10,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [barColor.withValues(alpha: 0.6), barColor],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildCategorySpendingChart(List<Player> players) {
    // Group sold players by category
    final categoryTotals = <String, double>{};
    final categoryCounts = <String, int>{};

    for (final p in players) {
      final cat = p.category.isNotEmpty ? p.category : 'General';
      if (p.status == PlayerStatus.sold) {
        categoryTotals[cat] = (categoryTotals[cat] ?? 0.0) + (p.soldPrice ?? 0.0);
        categoryCounts[cat] = (categoryCounts[cat] ?? 0) + 1;
      } else {
        categoryTotals.putIfAbsent(cat, () => 0.0);
        categoryCounts.putIfAbsent(cat, () => 0);
      }
    }

    if (categoryTotals.isEmpty) {
      return const GlassCard(
        height: 320,
        child: Center(
          child: Text('No categories or players available.', style: TextStyle(color: AppColors.textSecondary)),
        ),
      );
    }

    final categories = categoryTotals.keys.toList();
    final maxCategorySpend = categoryTotals.values.fold<double>(0.0, math.max);

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Category Spending & Count',
                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.secondaryPurple.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text('${categories.length} Roles', style: const TextStyle(color: AppColors.secondaryPurple, fontSize: 11)),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'Capital allocated (bars) & player count per role',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 220,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: maxCategorySpend > 0 ? maxCategorySpend * 1.15 : 100000,
                barTouchData: BarTouchData(
                  enabled: true,
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (_) => AppColors.card,
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final cat = categories[groupIndex];
                      final spend = categoryTotals[cat] ?? 0.0;
                      final count = categoryCounts[cat] ?? 0;
                      return BarTooltipItem(
                        '$cat\n${CurrencyFormatter.formatInr(spend)}\n$count sold',
                        const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 42,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          CurrencyFormatter.formatShort(value),
                          style: const TextStyle(color: AppColors.textMuted, fontSize: 10),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final idx = value.toInt();
                        if (idx >= 0 && idx < categories.length) {
                          final cat = categories[idx];
                          final label = cat.length > 7 ? '${cat.substring(0, 6)}..' : cat;
                          return Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 10)),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: AppColors.cardBorder.withValues(alpha: 0.3),
                    strokeWidth: 1,
                  ),
                ),
                borderData: FlBorderData(show: false),
                barGroups: categories.asMap().entries.map((entry) {
                  final idx = entry.key;
                  final cat = entry.value;
                  final spend = categoryTotals[cat] ?? 0.0;
                  final barColor = _colorForIndex(idx);

                  return BarChartGroupData(
                    x: idx,
                    barRods: [
                      BarChartRodData(
                        toY: spend,
                        gradient: LinearGradient(
                          colors: [barColor, barColor.withValues(alpha: 0.6)],
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                        ),
                        width: 18,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Category legend + counts
          Wrap(
            spacing: 12,
            runSpacing: 6,
            children: categories.asMap().entries.map((entry) {
              final idx = entry.key;
              final cat = entry.value;
              final count = categoryCounts[cat] ?? 0;
              final color = _colorForIndex(idx);

              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
                  const SizedBox(width: 4),
                  Text('$cat: ', style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                  Text('$count sold', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // ROW 2 CHARTS:
  // - Bid Activity Timeline (line chart by time)
  // - Purse Left vs Spent donut per team
  // ==========================================
  Widget _buildSecondChartsRow(List<Bid> bids, List<Team> teams) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 880;
        final halfWidth = (constraints.maxWidth - 16) / 2;

        return isWide
            ? Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(width: halfWidth, child: _buildBidTimelineChart(bids)),
                  const SizedBox(width: 16),
                  SizedBox(width: halfWidth, child: _buildPurseDonutChart(teams)),
                ],
              )
            : Column(
                children: [
                  _buildBidTimelineChart(bids),
                  const SizedBox(height: 16),
                  _buildPurseDonutChart(teams),
                ],
              );
      },
    );
  }

  Widget _buildBidTimelineChart(List<Bid> bids) {
    final sortedBids = List<Bid>.from(bids)..sort((a, b) => a.timestamp.compareTo(b.timestamp));

    if (sortedBids.isEmpty) {
      return const GlassCard(
        height: 320,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.timeline_rounded, color: AppColors.textMuted, size: 36),
              SizedBox(height: 8),
              Text('No bid activity recorded yet.', style: TextStyle(color: AppColors.textSecondary)),
              SizedBox(height: 4),
              Text('Bids placed in live auction will graph in real time.', style: TextStyle(color: AppColors.textMuted, fontSize: 11)),
            ],
          ),
        ),
      );
    }

    final spots = <FlSpot>[];
    for (int i = 0; i < sortedBids.length; i++) {
      spots.add(FlSpot(i.toDouble(), sortedBids[i].amount));
    }

    final maxBid = sortedBids.map((b) => b.amount).reduce(math.max);

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Bid Activity Timeline',
                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.accentPink.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text('${sortedBids.length} Bid Events', style: const TextStyle(color: AppColors.accentPink, fontSize: 11)),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text('Progression of bid amounts placed across session', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
          const SizedBox(height: 20),
          SizedBox(
            height: 230,
            child: LineChart(
              LineChartData(
                minX: 0,
                maxX: (spots.length - 1).toDouble().clamp(1.0, double.infinity),
                minY: 0,
                maxY: maxBid > 0 ? maxBid * 1.15 : 100000,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: AppColors.cardBorder.withValues(alpha: 0.3),
                    strokeWidth: 1,
                  ),
                ),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 42,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          CurrencyFormatter.formatShort(value),
                          style: const TextStyle(color: AppColors.textMuted, fontSize: 10),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: math.max(1, (spots.length / 5).floor().toDouble()),
                      getTitlesWidget: (value, meta) {
                        final idx = value.toInt();
                        if (idx >= 0 && idx < sortedBids.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text('#$idx', style: const TextStyle(color: AppColors.textMuted, fontSize: 10)),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipColor: (_) => AppColors.card,
                    getTooltipItems: (touchedSpots) {
                      return touchedSpots.map((spot) {
                        final bid = sortedBids[spot.x.toInt()];
                        final timeStr = '${bid.timestamp.hour.toString().padLeft(2, '0')}:${bid.timestamp.minute.toString().padLeft(2, '0')}:${bid.timestamp.second.toString().padLeft(2, '0')}';
                        return LineTooltipItem(
                          '${CurrencyFormatter.formatInr(spot.y)}\nTime: $timeStr',
                          const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                        );
                      }).toList();
                    },
                  ),
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    curveSmoothness: 0.35,
                    color: AppColors.accentPink,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: spots.length <= 25,
                      getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
                        radius: 3.5,
                        color: AppColors.accentPink,
                        strokeColor: Colors.white,
                        strokeWidth: 1.5,
                      ),
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          AppColors.accentPink.withValues(alpha: 0.35),
                          AppColors.accentPink.withValues(alpha: 0.0),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPurseDonutChart(List<Team> teams) {
    if (teams.isEmpty) {
      return const GlassCard(
        height: 320,
        child: Center(
          child: Text('No teams to display purse allocation.', style: TextStyle(color: AppColors.textSecondary)),
        ),
      );
    }

    // Default to first team or user-selected
    final activeTeam = teams.firstWhere(
      (t) => t.id == _selectedTeamForDonut,
      orElse: () => teams.first,
    );

    final spent = activeTeam.purseSpent;
    final remaining = activeTeam.purseRemaining;
    final total = activeTeam.purseTotal > 0 ? activeTeam.purseTotal : (spent + remaining);
    final spentRatio = total > 0 ? (spent / total * 100) : 0.0;
    final remainRatio = total > 0 ? (remaining / total * 100) : 100.0;

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              const Text(
                'Purse Left vs Spent Donut',
                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              ),
              // Team picker for Donut
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    dropdownColor: AppColors.card,
                    value: activeTeam.id,
                    icon: const Icon(Icons.arrow_drop_down, color: AppColors.primaryBlue, size: 18),
                    items: teams.map((t) {
                      return DropdownMenuItem<String>(
                        value: t.id,
                        child: Text(t.name, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                      );
                    }).toList(),
                    onChanged: (id) => setState(() => _selectedTeamForDonut = id),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Cap utilization for ${activeTeam.name}',
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: 200,
            child: Stack(
              alignment: Alignment.center,
              children: [
                PieChart(
                  PieChartData(
                    pieTouchData: PieTouchData(
                      touchCallback: (event, response) {
                        setState(() {
                          if (!event.isInterestedForInteractions || response == null || response.touchedSection == null) {
                            _touchedPieIndex = -1;
                            return;
                          }
                          _touchedPieIndex = response.touchedSection!.touchedSectionIndex;
                        });
                      },
                    ),
                    borderData: FlBorderData(show: false),
                    sectionsSpace: 4,
                    centerSpaceRadius: 55,
                    sections: [
                      PieChartSectionData(
                        color: AppColors.accentPink,
                        value: spent > 0 ? spent : 0.0001,
                        title: '${spentRatio.toStringAsFixed(0)}%',
                        radius: _touchedPieIndex == 0 ? 32 : 26,
                        titleStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      PieChartSectionData(
                        color: AppColors.success,
                        value: remaining > 0 ? remaining : 0.0001,
                        title: '${remainRatio.toStringAsFixed(0)}%',
                        radius: _touchedPieIndex == 1 ? 32 : 26,
                        titleStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ],
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      CurrencyFormatter.formatShort(total),
                      style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const Text('Total Purse', style: TextStyle(color: AppColors.textMuted, fontSize: 10)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Row(
                children: [
                  Container(width: 12, height: 12, decoration: const BoxDecoration(color: AppColors.accentPink, shape: BoxShape.circle)),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Spent', style: TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                      Text(CurrencyFormatter.formatInr(spent), style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ],
              ),
              Row(
                children: [
                  Container(width: 12, height: 12, decoration: const BoxDecoration(color: AppColors.success, shape: BoxShape.circle)),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Remaining', style: TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                      Text(CurrencyFormatter.formatInr(remaining), style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ==========================================
  // NEW INSIGHTS SECTION:
  // - Most Bids on a Player & Fastest Sold
  // - Bidding War meter
  // - Team Balance score (squad role mix)
  // - Village-wise player count
  // ==========================================
  Widget _buildNewInsightsSection(List<Player> players, List<Bid> bids, List<Team> teams) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.bolt_rounded, color: AppColors.gold, size: 22),
            SizedBox(width: 8),
            Text(
              'Advanced Intelligence & Special Insights',
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth > 880;
            final halfWidth = (constraints.maxWidth - 16) / 2;

            return isWide
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(width: halfWidth, child: _buildBiddingWarAndHighlights(players, bids)),
                      const SizedBox(width: 16),
                      SizedBox(width: halfWidth, child: _buildTeamBalanceAndVillages(players, teams)),
                    ],
                  )
                : Column(
                    children: [
                      _buildBiddingWarAndHighlights(players, bids),
                      const SizedBox(height: 16),
                      _buildTeamBalanceAndVillages(players, teams),
                    ],
                  );
          },
        ),
      ],
    );
  }

  Widget _buildBiddingWarAndHighlights(List<Player> players, List<Bid> bids) {
    // Count bids per player
    final bidCountPerPlayer = <String, int>{};
    final bidsForPlayer = <String, List<Bid>>{};

    for (final b in bids) {
      bidCountPerPlayer[b.playerId] = (bidCountPerPlayer[b.playerId] ?? 0) + 1;
      bidsForPlayer.putIfAbsent(b.playerId, () => []).add(b);
    }

    final playerById = {for (final p in players) p.id: p};

    // Sorted by most bids
    final sortedPlayerIds = bidCountPerPlayer.keys.toList()
      ..sort((a, b) => (bidCountPerPlayer[b] ?? 0).compareTo(bidCountPerPlayer[a] ?? 0));

    final topWarPlayers = sortedPlayerIds.take(4).toList();

    // Most Bids on a Player
    final mostBidsPlayerId = sortedPlayerIds.isNotEmpty ? sortedPlayerIds.first : null;
    final mostBidsPlayer = mostBidsPlayerId != null ? playerById[mostBidsPlayerId] : null;
    final mostBidsCount = mostBidsPlayerId != null ? (bidCountPerPlayer[mostBidsPlayerId] ?? 0) : 0;

    // Fastest Sold (lowest bid duration from first to last bid)
    String fastestPlayerName = 'N/A';
    String fastestDuration = 'Instant';

    int minDurationSeconds = 9999999;
    for (final entry in bidsForPlayer.entries) {
      if (entry.value.length >= 2) {
        final times = entry.value.map((b) => b.timestamp).toList()..sort();
        final diff = times.last.difference(times.first).inSeconds;
        if (diff > 0 && diff < minDurationSeconds) {
          minDurationSeconds = diff;
          fastestPlayerName = playerById[entry.key]?.name ?? 'Player';
          fastestDuration = '${diff}s';
        }
      }
    }

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Bidding War Meter & Speed Records',
            style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          const Text('Players with the fiercest bidding duels and speed metrics', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
          const SizedBox(height: 16),
          // Highlights row: Most bids + Fastest sold
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceLight,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.gold.withValues(alpha: 0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.local_fire_department_rounded, color: AppColors.gold, size: 16),
                          SizedBox(width: 4),
                          Text('Most Bids on Player', style: TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        mostBidsPlayer?.name ?? 'No duel yet',
                        style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        '$mostBidsCount bids placed',
                        style: const TextStyle(color: AppColors.gold, fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceLight,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.info.withValues(alpha: 0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.speed_rounded, color: AppColors.info, size: 16),
                          SizedBox(width: 4),
                          Text('Fastest Sold', style: TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        fastestPlayerName,
                        style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'Concluded in $fastestDuration',
                        style: const TextStyle(color: AppColors.info, fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          const Text('Bidding War Meter (Most Contested Players):', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
          const SizedBox(height: 10),
          if (topWarPlayers.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text('No bidding wars recorded yet.', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
            )
          else
            ...topWarPlayers.map((pid) {
              final player = playerById[pid];
              final count = bidCountPerPlayer[pid] ?? 0;
              final maxWarBids = (bidCountPerPlayer[topWarPlayers.first] ?? 1).toDouble();
              final ratio = (count / maxWarBids).clamp(0.0, 1.0);

              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(player?.name ?? pid, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                        Text('$count bids', style: const TextStyle(color: AppColors.accentPink, fontSize: 11, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: Stack(
                        children: [
                          Container(height: 8, color: AppColors.surfaceLight),
                          FractionallySizedBox(
                            widthFactor: ratio,
                            child: Container(
                              height: 8,
                              decoration: const BoxDecoration(
                                gradient: LinearGradient(colors: [AppColors.gold, AppColors.accentPink]),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildTeamBalanceAndVillages(List<Player> players, List<Team> teams) {
    // Village-wise player counts
    final villageCounts = <String, int>{};
    for (final p in players) {
      final v = p.village.trim().isNotEmpty ? p.village.trim() : 'Unspecified';
      villageCounts[v] = (villageCounts[v] ?? 0) + 1;
    }

    final topVillages = villageCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // Team balance score based on role diversity (Batsman, Bowler, All-Rounder, Wicketkeeper)
    final teamScores = <String, int>{};
    for (final team in teams) {
      final teamPlayers = players.where((p) => p.soldTeamId == team.id).toList();
      final distinctCategories = teamPlayers.map((p) => p.category.toLowerCase().trim()).toSet();
      // Score out of 100 based on role coverage and squad size
      final coverageScore = (distinctCategories.length / 4.0) * 60;
      final sizeScore = math.min(40.0, (teamPlayers.length / 11.0) * 40);
      teamScores[team.id] = (coverageScore + sizeScore).round().clamp(0, 100);
    }

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Squad Balance & Village Demographics',
            style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          const Text('Team squad role mix score & player origins', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
          const SizedBox(height: 14),
          const Text('Team Balance Score (Role Mix Diversity):', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          if (teams.isEmpty)
            const Text('No teams to score.', style: TextStyle(color: AppColors.textMuted, fontSize: 12))
          else
            ...teams.take(3).map((t) {
              final score = teamScores[t.id] ?? 0;
              final scoreColor = score >= 75 ? AppColors.success : (score >= 50 ? AppColors.gold : AppColors.accentPink);

              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: Text(t.name, style: const TextStyle(color: Colors.white, fontSize: 12)),
                    ),
                    Expanded(
                      flex: 4,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: score / 100.0,
                          backgroundColor: AppColors.surfaceLight,
                          valueColor: AlwaysStoppedAnimation<Color>(scoreColor),
                          minHeight: 8,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 44,
                      child: Text('$score/100', style: TextStyle(color: scoreColor, fontSize: 11, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              );
            }),
          const SizedBox(height: 14),
          const Text('Village-Wise Player Count (Top Origins):', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: topVillages.take(6).map((e) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.location_on_rounded, color: AppColors.primaryBlue, size: 14),
                    const SizedBox(width: 4),
                    Text(e.key, style: const TextStyle(color: Colors.white, fontSize: 12)),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(
                        color: AppColors.primaryBlue.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text('${e.value}', style: const TextStyle(color: AppColors.primaryBlue, fontSize: 10, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // PRICE VS STRIKE RATE SCATTER CHART
  // ==========================================
  Widget _buildScatterSection(List<Player> players) {
    final validPlayers = players.where((p) => p.strikeRate > 0).toList();

    if (validPlayers.isEmpty) {
      return GlassCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Price vs Strike Rate Correlation',
              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            const Text('Player valuation mapped against batting strike rate', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
            const SizedBox(height: 30),
            Center(
              child: Column(
                children: [
                  Icon(Icons.scatter_plot_rounded, color: AppColors.textMuted.withValues(alpha: 0.5), size: 48),
                  const SizedBox(height: 10),
                  const Text('No players with recorded Strike Rate (>0).', style: TextStyle(color: AppColors.textSecondary)),
                  const SizedBox(height: 4),
                  const Text('Add strike rate in player profiles to view valuation efficiency.', style: TextStyle(color: AppColors.textMuted, fontSize: 11)),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      );
    }

    final maxStrikeRate = validPlayers.map((p) => p.strikeRate).reduce(math.max);
    final maxPrice = validPlayers.map((p) => (p.soldPrice ?? p.basePrice)).reduce(math.max);

    final scatterSpots = validPlayers.map((p) {
      final price = (p.soldPrice ?? p.basePrice);
      final isSold = p.status == PlayerStatus.sold;
      return ScatterSpot(
        p.strikeRate,
        price,
        dotPainter: FlDotCirclePainter(
          radius: isSold ? 6.0 : 4.0,
          color: isSold ? AppColors.accentPink : AppColors.primaryBlue,
          strokeColor: Colors.white,
          strokeWidth: isSold ? 1.5 : 0.8,
        ),
      );
    }).toList();

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Price vs Strike Rate Scatter Chart',
                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              ),
              Row(
                children: [
                  Container(width: 8, height: 8, decoration: const BoxDecoration(color: AppColors.accentPink, shape: BoxShape.circle)),
                  const SizedBox(width: 4),
                  const Text('Sold', style: TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                  const SizedBox(width: 12),
                  Container(width: 8, height: 8, decoration: const BoxDecoration(color: AppColors.primaryBlue, shape: BoxShape.circle)),
                  const SizedBox(width: 4),
                  const Text('Available', style: TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text('X-axis: Batting Strike Rate | Y-axis: Final Sold / Base Price', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
          const SizedBox(height: 20),
          SizedBox(
            height: 260,
            child: ScatterChart(
              ScatterChartData(
                scatterSpots: scatterSpots,
                minX: 0,
                maxX: maxStrikeRate > 0 ? maxStrikeRate * 1.15 : 200,
                minY: 0,
                maxY: maxPrice > 0 ? maxPrice * 1.15 : 100000,
                borderData: FlBorderData(show: false),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: true,
                  getDrawingHorizontalLine: (value) => FlLine(color: AppColors.cardBorder.withValues(alpha: 0.25), strokeWidth: 1),
                  getDrawingVerticalLine: (value) => FlLine(color: AppColors.cardBorder.withValues(alpha: 0.25), strokeWidth: 1),
                ),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 44,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          CurrencyFormatter.formatShort(value),
                          style: const TextStyle(color: AppColors.textMuted, fontSize: 10),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text('${value.toInt()} SR', style: const TextStyle(color: AppColors.textMuted, fontSize: 10)),
                        );
                      },
                    ),
                  ),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                scatterTouchData: ScatterTouchData(
                  enabled: true,
                  touchTooltipData: ScatterTouchTooltipData(
                    getTooltipColor: (_) => AppColors.card,
                    getTooltipItems: (touchedSpot) {
                      final p = validPlayers.firstWhere(
                        (pl) => pl.strikeRate == touchedSpot.x && (pl.soldPrice ?? pl.basePrice) == touchedSpot.y,
                        orElse: () => validPlayers.first,
                      );
                      return ScatterTooltipItem(
                        '${p.name}\nSR: ${p.strikeRate}\nPrice: ${CurrencyFormatter.formatInr(touchedSpot.y)}',
                        textStyle: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
