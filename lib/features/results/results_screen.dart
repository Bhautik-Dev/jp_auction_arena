import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:csv/csv.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/gradient_button.dart';
import '../../data/models/models.dart';
import '../../data/repositories/repositories.dart';
import '../../shared/widgets/app_ui_feedback.dart';

class ResultsScreen extends ConsumerStatefulWidget {
  const ResultsScreen({super.key});

  @override
  ConsumerState<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends ConsumerState<ResultsScreen> {
  String? _selectedAuctionId;
  String _searchQuery = '';
  String? _selectedCategory;
  String? _selectedStatus;
  String _viewMode = 'all';
  String? _selectedTeamId;
  bool _isLoading = false;

  List<Auction> _auctions = [];
  List<Player> _players = [];
  List<Team> _teams = [];
  Auction? _selectedAuction;

  @override
  void initState() {
    super.initState();
  }

  Future<void> _loadAuctions() async {
    try {
      final auctions = await ref.read(auctionRepositoryProvider).getAll();
      if (!mounted) return;
      setState(() {
        _auctions = auctions..sort((a, b) => b.createdAt.compareTo(a.createdAt));
        if (_selectedAuctionId == null && auctions.isNotEmpty) {
          _selectedAuctionId = auctions.first.id;
        }
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _auctions = [];
      });
    }
    _loadAuctionData();
  }

  Future<void> _loadAuctionData() async {
    if (_selectedAuctionId == null) return;
    setState(() => _isLoading = true);

    try {
      final players = await ref.read(playerRepositoryProvider).getByAuctionId(_selectedAuctionId!);
      final teams = await ref.read(teamRepositoryProvider).getByAuctionId(_selectedAuctionId!);
      final auction = await ref.read(auctionRepositoryProvider).getById(_selectedAuctionId!);

      if (!mounted) return;
      setState(() {
        _players = players..sort((a, b) => a.playerNo.compareTo(b.playerNo));
        _teams = teams;
        _selectedAuction = auction;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  Future<void> _refresh() async {
    await _loadAuctionData();
    if (mounted) AppToast.showSuccess(context, 'Data refreshed');
  }

  Future<void> _exportCSV() async {
    final filtered = _filteredPlayers;
    if (filtered.isEmpty) {
      AppToast.showError(context, 'No data to export');
      return;
    }

    final rows = <List<dynamic>>[
      ['Player No', 'Name', 'Village', 'Category', 'Base Price', 'Sold Price', 'Team', 'Status'],
    ];

    for (final p in filtered) {
      final team = _teams.firstWhere((t) => t.id == p.soldTeamId, orElse: () => Team(id: '', auctionId: '', name: '-', purseTotal: 0, purseSpent: 0));
      rows.add([
        p.playerNo,
        p.name,
        p.village,
        p.category,
        formatRupee(p.basePrice),
        p.soldPrice != null ? formatRupee(p.soldPrice!) : '-',
        team.name,
        p.status.displayName,
      ]);
    }

    const ListToCsvConverter().convert(rows);

    if (mounted) {
      AppToast.showSuccess(context, 'CSV exported successfully');
    }
  }

  void _exportExcel() {
    AppToast.showSuccess(context, 'Excel export coming soon');
  }

  void _exportPDF() {
    AppToast.showSuccess(context, 'PDF export coming soon');
  }

  List<Player> get _filteredPlayers {
    var result = _players.where((p) {
      final matchesSearch = p.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          p.playerNo.toString().contains(_searchQuery);
      final matchesCategory = _selectedCategory == null || p.category == _selectedCategory;
      final matchesStatus = _selectedStatus == null ||
          _selectedStatus == 'all' ||
          (_selectedStatus == 'sold' && p.status == PlayerStatus.sold) ||
          (_selectedStatus == 'unsold' && p.status == PlayerStatus.unsold);
      return matchesSearch && matchesCategory && matchesStatus;
    }).toList();

    if (_viewMode == 'individual' && _selectedTeamId != null) {
      result = result.where((p) => p.soldTeamId == _selectedTeamId).toList();
    }

    return result;
  }

  int get _soldCount => _filteredPlayers.where((p) => p.status == PlayerStatus.sold).length;
  int get _unsoldCount => _filteredPlayers.where((p) => p.status == PlayerStatus.unsold).length;
  double get _totalSpend => _filteredPlayers
      .where((p) => p.status == PlayerStatus.sold)
      .fold(0.0, (sum, p) => sum + (p.soldPrice ?? 0));

  List<String> get _categories {
    final cats = _players.map((p) => p.category).toSet().toList()..sort();
    return cats;
  }

  String _getTeamName(String? teamId) {
    if (teamId == null) return '-';
    final team = _teams.firstWhere((t) => t.id == teamId, orElse: () => Team(id: '', auctionId: '', name: '-', purseTotal: 0, purseSpent: 0));
    return team.name;
  }

  Widget _buildPlayerAvatar(Player player) {
    if (player.photoBase64 != null && player.photoBase64!.isNotEmpty) {
      try {
        return CircleAvatar(
          radius: 18,
          backgroundImage: MemoryImage(base64Decode(player.photoBase64!)),
        );
      } catch (_) {
        return _buildAvatarPlaceholder(player);
      }
    }
    return _buildAvatarPlaceholder(player);
  }

  Widget _buildAvatarPlaceholder(Player player) {
    return CircleAvatar(
      radius: 18,
      backgroundColor: AppColors.secondaryPurple.withValues(alpha: 0.2),
      child: Text(
        player.name.isNotEmpty ? player.name[0].toUpperCase() : '?',
        style: const TextStyle(
          color: AppColors.secondaryPurple,
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
      ),
    );
  }

  Widget _buildStatusBadge(PlayerStatus status) {
    final isSold = status == PlayerStatus.sold;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: (isSold ? AppColors.success : AppColors.error).withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: (isSold ? AppColors.success : AppColors.error).withValues(alpha: 0.5),
          width: 1,
        ),
      ),
      child: Text(
        status.displayName.toUpperCase(),
        style: TextStyle(
          color: isSold ? AppColors.success : AppColors.error,
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return GlassCard(
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 12,
            runSpacing: 12,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primaryBlue.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.checklist_rounded, color: AppColors.primaryBlue, size: 24),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Auction Results',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _selectedAuction != null
                        ? 'Results for "${_selectedAuction!.name}"'
                        : 'Select an auction to view results',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
              _buildAuctionDropdown(),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              GradientButton(
                onPressed: _refresh,
                icon: Icons.refresh_rounded,
                label: 'Refresh',
                width: 100,
              ),
              GradientButton(
                onPressed: _exportCSV,
                icon: Icons.file_download_rounded,
                label: 'Export CSV',
                width: 110,
              ),
              GradientButton(
                onPressed: _exportExcel,
                icon: Icons.table_view_rounded,
                label: 'Export Excel',
                width: 110,
              ),
              GradientButton(
                onPressed: _exportPDF,
                icon: Icons.picture_as_pdf_rounded,
                label: 'Download PDF',
                width: 110,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              Icon(Icons.category_rounded, color: AppColors.textSecondary, size: 16),
              const SizedBox(width: 8),
              Text(
                'Category & Custom PDF',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
              ),
              DropdownButton<String?>(
                value: _selectedCategory,
                hint: const Text('All Categories', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                dropdownColor: AppColors.card,
                style: const TextStyle(color: Colors.white, fontSize: 12),
                items: [
                  const DropdownMenuItem<String?>(value: null, child: Text('All Categories')),
                  ..._categories.map((c) => DropdownMenuItem<String?>(value: c, child: Text(c))),
                ],
                onChanged: (v) => setState(() => _selectedCategory = v),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAuctionDropdown() {
    return SizedBox(
      width: 220,
      child: DropdownButton<String?>(
        value: _selectedAuctionId,
        hint: const Text('Select Auction', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
        dropdownColor: AppColors.card,
        style: const TextStyle(color: Colors.white, fontSize: 12),
        isExpanded: true,
        items: [
          const DropdownMenuItem<String?>(value: null, child: Text('All Auctions')),
          ..._auctions.map((a) => DropdownMenuItem<String?>(value: a.id, child: Text(a.name, overflow: TextOverflow.ellipsis))),
        ],
        onChanged: (v) async {
          setState(() {
            _selectedAuctionId = v;
            _selectedTeamId = null;
          });
          await _loadAuctions();
          await _loadAuctionData();
        },
      ),
    );
  }

  Widget _buildStats() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _buildStatCard('Total Sold', '$_soldCount', AppColors.success, Icons.check_circle_rounded),
            _buildStatCard('Total Unsold', '$_unsoldCount', AppColors.error, Icons.cancel_rounded),
            _buildStatCard('Total Spend', formatRupee(_totalSpend), AppColors.gold, Icons.attach_money_rounded),
          ],
        );
      },
    );
  }

  Widget _buildStatCard(String title, String value, Color color, IconData icon) {
    return SizedBox(
      width: 200,
      child: GlassCard(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                  const SizedBox(height: 4),
                  Text(value, style: TextStyle(color: color, fontSize: 20, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilters() {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Filters', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              SizedBox(
                width: double.infinity,
                child: TextField(
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Search players by name or number',
                    hintStyle: TextStyle(color: AppColors.textMuted, fontSize: 12),
                    prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textSecondary, size: 18),
                    filled: true,
                    fillColor: AppColors.surfaceLight,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: AppColors.cardBorder),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: AppColors.cardBorder),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: AppColors.primaryBlue, width: 1.5),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  ),
                  onChanged: (v) => setState(() => _searchQuery = v),
                ),
              ),
              SizedBox(
                width: 150,
                child: DropdownButton<String?>(
                  value: _selectedCategory,
                  hint: const Text('Category', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                  dropdownColor: AppColors.card,
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                  isExpanded: true,
                  items: [
                    const DropdownMenuItem<String?>(value: null, child: Text('All Categories')),
                    ..._categories.map((c) => DropdownMenuItem<String?>(value: c, child: Text(c))),
                  ],
                  onChanged: (v) => setState(() => _selectedCategory = v),
                ),
              ),
              SizedBox(
                width: 130,
                child: DropdownButton<String?>(
                  value: _selectedStatus,
                  hint: const Text('Status', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                  dropdownColor: AppColors.card,
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                  isExpanded: true,
                  items: [
                    const DropdownMenuItem<String?>(value: 'all', child: Text('All Status')),
                    const DropdownMenuItem<String?>(value: 'sold', child: Text('Sold')),
                    const DropdownMenuItem<String?>(value: 'unsold', child: Text('Unsold')),
                  ],
                  onChanged: (v) => setState(() => _selectedStatus = v),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildViewMode() {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('View Mode', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildModeChip('all', 'All Players', Icons.list_rounded),
              _buildModeChip('team-wise', 'Team-Wise', Icons.groups_rounded),
              _buildModeChip('all-teams', 'All Teams Overview', Icons.view_list_rounded),
              _buildModeChip('individual', 'Individual Team', Icons.person_rounded),
            ],
          ),
          if (_viewMode == 'individual') ...[
            const SizedBox(height: 12),
            const Text('Select Team', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
            const SizedBox(height: 8),
            SizedBox(
              width: 250,
              child: DropdownButton<String?>(
                value: _selectedTeamId,
                hint: const Text('Select a team', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                dropdownColor: AppColors.card,
                style: const TextStyle(color: Colors.white, fontSize: 12),
                isExpanded: true,
                items: [
                  const DropdownMenuItem<String?>(value: null, child: Text('All Teams')),
                  ..._teams.map((t) => DropdownMenuItem<String?>(value: t.id, child: Text(t.name))),
                ],
                onChanged: (v) => setState(() => _selectedTeamId = v),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildModeChip(String mode, String label, IconData icon) {
    final isSelected = _viewMode == mode;
    return ChoiceChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: isSelected ? Colors.white : AppColors.textSecondary),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(color: isSelected ? Colors.white : AppColors.textSecondary, fontSize: 12)),
        ],
      ),
      selected: isSelected,
      onSelected: (selected) => setState(() => _viewMode = mode),
      selectedColor: AppColors.primaryBlue,
      backgroundColor: AppColors.surfaceLight,
      labelStyle: const TextStyle(fontSize: 12),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: isSelected ? AppColors.primaryBlue : AppColors.cardBorder,
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading results...', style: TextStyle(color: AppColors.textSecondary)),
          ],
        ),
      );
    }

    if (_selectedAuctionId == null || _players.isEmpty) {
      return Center(
        child: AppEmptyState(
          icon: Icons.assignment_late_rounded,
          title: 'No Results Available',
          description: _selectedAuctionId == null
              ? 'Please select an auction from the dropdown to view results.'
              : 'No players found for the selected auction.',
          action: _auctions.isNotEmpty
              ? GradientButton(
                  onPressed: () {},
                  label: 'Select Auction',
                  width: 140,
                )
              : null,
        ),
      );
    }

    final filtered = _filteredPlayers;

    if (filtered.isEmpty) {
      return Center(
        child: AppEmptyState(
          icon: Icons.filter_alt_rounded,
          title: 'No Matching Results',
          description: 'Try adjusting your search or filter criteria.',
          action: GradientButton(
            onPressed: () => setState(() {
              _searchQuery = '';
              _selectedCategory = null;
              _selectedStatus = null;
            }),
            label: 'Clear Filters',
            width: 140,
          ),
        ),
      );
    }

    switch (_viewMode) {
      case 'team-wise':
        return _buildTeamWiseView(filtered);
      case 'all-teams':
        return _buildAllTeamsOverview(filtered);
      case 'individual':
        return _buildIndividualTeamView(filtered);
      case 'all':
      default:
        return _buildAllPlayersView(filtered);
    }
  }

  Widget _buildAllPlayersView(List<Player> players) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 900;

        return GlassCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'All Players (${players.length})',
                style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 14),
              if (isCompact)
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: _buildPlayerTable(players, isCompact: true),
                )
              else
                _buildPlayerTable(players, isCompact: false),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPlayerTable(List<Player> players, {required bool isCompact}) {
    final headers = [
      'Photo', 'Player', 'Village', 'Category', 'Base Price', 'Sold Price', 'Team', 'Status', 'Actions',
    ];

    return DataTable(
      columnSpacing: 16,
      headingRowColor: WidgetStateProperty.all(AppColors.surfaceLight),
      headingTextStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.bold),
      dataTextStyle: const TextStyle(color: Colors.white, fontSize: 12),
      columns: headers.map((h) => DataColumn(label: Text(h))).toList(),
      rows: players.map((p) {
        final teamName = _getTeamName(p.soldTeamId);
        final isSold = p.status == PlayerStatus.sold;
        return DataRow(cells: [
          DataCell(_buildPlayerAvatar(p)),
          DataCell(Text(p.name, style: const TextStyle(fontWeight: FontWeight.w600))),
          DataCell(Text(p.village.isEmpty ? '-' : p.village, style: const TextStyle(fontSize: 11))),
          DataCell(Text(p.category, style: const TextStyle(fontSize: 11))),
          DataCell(Text(formatRupee(p.basePrice), style: const TextStyle(fontSize: 11))),
          DataCell(Text(
            p.soldPrice != null ? formatRupee(p.soldPrice!) : '-',
            style: TextStyle(color: isSold ? AppColors.success : AppColors.textMuted, fontSize: 11, fontWeight: FontWeight.w600),
          )),
          DataCell(Text(teamName, style: const TextStyle(fontSize: 11))),
          DataCell(_buildStatusBadge(p.status)),
          DataCell(
            isCompact
                ? IconButton(
                    icon: const Icon(Icons.visibility_rounded, color: AppColors.primaryBlue, size: 18),
                    onPressed: () => _showPlayerDetails(p),
                    constraints: const BoxConstraints(),
                    padding: EdgeInsets.zero,
                    visualDensity: VisualDensity.compact,
                  )
                : GradientButton(
                    onPressed: () => _showPlayerDetails(p),
                    icon: Icons.visibility_rounded,
                    label: 'View',
                    width: 70,
                    height: 32,
                  ),
          ),
        ]);
      }).toList(),
    );
  }

  Widget _buildTeamWiseView(List<Player> players) {
    final Map<String, List<Player>> teamsGrouped = {};
    for (final p in players) {
      if (p.status == PlayerStatus.sold && p.soldTeamId != null) {
        teamsGrouped.putIfAbsent(p.soldTeamId!, () => []).add(p);
      }
    }

    final unsold = players.where((p) => p.status == PlayerStatus.unsold).toList();

    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 900;

        return GlassCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Team-Wise Results (${teamsGrouped.length} teams)',
                style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 14),
              ...teamsGrouped.entries.map((entry) {
                final team = _teams.firstWhere((t) => t.id == entry.key, orElse: () => Team(id: '', auctionId: '', name: '-', purseTotal: 0, purseSpent: 0));
                final teamPlayers = entry.value;
                final teamSpend = teamPlayers.fold(0.0, (s, p) => s + (p.soldPrice ?? 0));

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.primaryBlue.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(Icons.groups_rounded, color: AppColors.primaryBlue, size: 20),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  team.name,
                                  style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  '${teamPlayers.length} players  •  Spent: ${formatRupee(teamSpend)}',
                                  style: TextStyle(color: AppColors.textSecondary, fontSize: 11),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (isCompact)
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: _buildPlayerTable(teamPlayers, isCompact: true),
                      )
                    else
                      _buildPlayerTable(teamPlayers, isCompact: false),
                    const SizedBox(height: 20),
                  ],
                );
              }),
              if (unsold.isNotEmpty) ...[
                Text(
                  'Unsold Players (${unsold.length})',
                  style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                if (isCompact)
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: _buildPlayerTable(unsold, isCompact: true),
                  )
                else
                  _buildPlayerTable(unsold, isCompact: false),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildAllTeamsOverview(List<Player> players) {
    final Map<String, List<Player>> teamsGrouped = {};
    for (final p in players) {
      if (p.status == PlayerStatus.sold && p.soldTeamId != null) {
        teamsGrouped.putIfAbsent(p.soldTeamId!, () => []).add(p);
      }
    }

    final unsold = players.where((p) => p.status == PlayerStatus.unsold).toList();

    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 900;

        return GlassCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'All Teams Overview (${_teams.length} teams)',
                style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 14),
              ..._teams.map((t) {
                final teamPlayers = teamsGrouped[t.id] ?? [];
                final teamSpend = teamPlayers.fold(0.0, (s, p) => s + (p.soldPrice ?? 0));

                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  t.name,
                                  style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  '${teamPlayers.length} players  •  ₹${formatShort(teamSpend)} spent',
                                  style: TextStyle(color: AppColors.textSecondary, fontSize: 11),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.success.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '${teamPlayers.length}',
                              style: const TextStyle(color: AppColors.success, fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (teamPlayers.isEmpty)
                        const Text('No players purchased.', style: TextStyle(color: AppColors.textMuted, fontSize: 11))
                      else if (isCompact)
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: _buildPlayerTable(teamPlayers, isCompact: true),
                        )
                      else
                        _buildPlayerTable(teamPlayers, isCompact: false),
                    ],
                  ),
                );
              }),
              if (unsold.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(
                  'Unsold Players (${unsold.length})',
                  style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                if (isCompact)
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: _buildPlayerTable(unsold, isCompact: true),
                  )
                else
                  _buildPlayerTable(unsold, isCompact: false),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildIndividualTeamView(List<Player> players) {
    if (_selectedTeamId == null) {
      return Center(
        child: AppEmptyState(
          icon: Icons.person_rounded,
          title: 'Select a Team',
          description: 'Choose a team from the dropdown above to view its players.',
        ),
      );
    }

    final team = _teams.firstWhere((t) => t.id == _selectedTeamId, orElse: () => Team(id: '', auctionId: '', name: '-', purseTotal: 0, purseSpent: 0));
    if (team.name == '-') {
      return Center(
        child: AppEmptyState(
          icon: Icons.error_outline_rounded,
          title: 'Team Not Found',
          description: 'The selected team could not be found.',
        ),
      );
    }

    final teamPlayers = players.where((p) => p.soldTeamId == _selectedTeamId).toList();
    final teamSpend = teamPlayers.fold(0.0, (s, p) => s + (p.soldPrice ?? 0));

    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 900;

        return GlassCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.primaryBlue.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.person_rounded, color: AppColors.primaryBlue, size: 28),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          team.name,
                          style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800),
                        ),
                        Text(
                          '${teamPlayers.length} players  •  Total Spent: ${formatRupee(teamSpend)}  •  Remaining: ${formatRupee(team.purseRemaining)}',
                          style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (teamPlayers.isEmpty)
                const Text('No players purchased by this team.', style: TextStyle(color: AppColors.textMuted, fontSize: 12))
              else if (isCompact)
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: _buildPlayerTable(teamPlayers, isCompact: true),
                )
              else
                _buildPlayerTable(teamPlayers, isCompact: false),
            ],
          ),
        );
      },
    );
  }

  void _showPlayerDetails(Player player) {
    final team = _teams.firstWhere((t) => t.id == player.soldTeamId, orElse: () => Team(id: '', auctionId: '', name: '-', purseTotal: 0, purseSpent: 0));
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            _buildPlayerAvatar(player),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                player.name,
                style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _detailRow('Player No', '#${player.playerNo}'),
            _detailRow('Village', player.village.isEmpty ? '-' : player.village),
            _detailRow('Category', player.category),
            _detailRow('Status', player.status.displayName, statusColor: player.status == PlayerStatus.sold ? AppColors.success : AppColors.error),
            _detailRow('Base Price', formatRupee(player.basePrice)),
            if (player.soldPrice != null) _detailRow('Sold Price', formatRupee(player.soldPrice!), statusColor: AppColors.success),
            if (team.name != '-') _detailRow('Team', team.name),
            if (team.name != '-') _detailRow('Team Spend', formatRupee(team.purseSpent)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close', style: TextStyle(color: AppColors.textSecondary)),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value, {Color? statusColor}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: statusColor ?? Colors.white,
                fontSize: 12,
                fontWeight: statusColor != null ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            _buildStats(),
            const SizedBox(height: 4),
            _buildFilters(),
            _buildViewMode(),
            _buildContent(),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
