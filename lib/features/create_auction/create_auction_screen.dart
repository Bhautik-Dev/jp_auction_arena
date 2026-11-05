import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/gradient_button.dart';
import '../../data/models/models.dart';
import '../../data/repositories/repositories.dart';
import '../../shared/widgets/feature_placeholder_screen.dart';

class CreateAuctionScreen extends ConsumerStatefulWidget {
  final String? editAuctionId;

  const CreateAuctionScreen({
    super.key,
    this.editAuctionId,
  });

  @override
  ConsumerState<CreateAuctionScreen> createState() => _CreateAuctionScreenState();
}

class _CreateAuctionScreenState extends ConsumerState<CreateAuctionScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _venueController;
  late final TextEditingController _descController;
  late final TextEditingController _purseController;
  late final TextEditingController _basePriceController;
  late final TextEditingController _bidIncrementController;
  late final TextEditingController _teamsController;
  late final TextEditingController _minSquadController;
  late final TextEditingController _maxSquadController;
  late final TextEditingController _countdownController;

  AuctionMode _mode = AuctionMode.manual;
  AuctionStatus _status = AuctionStatus.draft;
  bool _isSaving = false;
  Auction? _existingAuction;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: 'Premier T20 Cup 2026');
    _venueController = TextEditingController(text: 'JP Sports Ground');
    _descController = TextEditingController(text: 'Official seasonal cricket auction');
    _purseController = TextEditingController(text: '1000000');
    _basePriceController = TextEditingController(text: '10000');
    _bidIncrementController = TextEditingController(text: '2000');
    _teamsController = TextEditingController(text: '8');
    _minSquadController = TextEditingController(text: '11');
    _maxSquadController = TextEditingController(text: '15');
    _countdownController = TextEditingController(text: '30');

    if (widget.editAuctionId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadExistingAuction();
      });
    }
  }

  void _loadExistingAuction() {
    final repo = ref.read(auctionRepositoryProvider);
    final a = repo.getById(widget.editAuctionId!);
    if (a != null) {
      setState(() {
        _existingAuction = a;
        _nameController.text = a.name;
        _venueController.text = a.venue;
        _descController.text = a.description;
        _purseController.text = a.teamPurse.toStringAsFixed(0);
        _basePriceController.text = a.basePriceDefault.toStringAsFixed(0);
        _bidIncrementController.text = a.bidIncrement.toStringAsFixed(0);
        _teamsController.text = a.numberOfTeams.toString();
        _minSquadController.text = a.minSquad.toString();
        _maxSquadController.text = a.maxSquad.toString();
        _countdownController.text = a.countdownSeconds.toString();
        _mode = a.mode;
        _status = a.status;
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _venueController.dispose();
    _descController.dispose();
    _purseController.dispose();
    _basePriceController.dispose();
    _bidIncrementController.dispose();
    _teamsController.dispose();
    _minSquadController.dispose();
    _maxSquadController.dispose();
    _countdownController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    final isEditing = _existingAuction != null;
    final id = isEditing
        ? _existingAuction!.id
        : 'auc_${DateTime.now().millisecondsSinceEpoch}';

    final auction = Auction(
      id: id,
      name: _nameController.text.trim(),
      venue: _venueController.text.trim(),
      description: _descController.text.trim(),
      startDateTime: _existingAuction?.startDateTime ?? DateTime.now(),
      status: _status,
      teamPurse: double.tryParse(_purseController.text.trim()) ?? 1000000,
      basePriceDefault: double.tryParse(_basePriceController.text.trim()) ?? 10000,
      bidIncrement: double.tryParse(_bidIncrementController.text.trim()) ?? 2000,
      numberOfTeams: int.tryParse(_teamsController.text.trim()) ?? 8,
      minSquad: int.tryParse(_minSquadController.text.trim()) ?? 11,
      maxSquad: int.tryParse(_maxSquadController.text.trim()) ?? 15,
      countdownSeconds: int.tryParse(_countdownController.text.trim()) ?? 30,
      mode: _mode,
      createdAt: _existingAuction?.createdAt ?? DateTime.now(),
    );

    await ref.read(auctionRepositoryProvider).save(auction);
    ref.read(activeAuctionIdProvider.notifier).setAuctionId(id);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isEditing
                ? 'Auction "${auction.name}" updated successfully!'
                : 'Auction "${auction.name}" created successfully!',
          ),
          backgroundColor: AppColors.success,
        ),
      );
      context.go('/auctions');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = _existingAuction != null;

    return FeaturePlaceholderScreen(
      title: isEditing ? 'Edit Auction Settings' : 'Create New Tournament',
      description: isEditing
          ? 'Modify tournament rules, squad sizes, and purse limits for "${_existingAuction!.name}"'
          : 'Define tournament rules, squad sizes, and purse limits',
      icon: isEditing ? Icons.tune_rounded : Icons.add_circle_outline_rounded,
      children: [
        Form(
          key: _formKey,
          child: GlassCard(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      isEditing ? 'Tournament Settings' : 'Tournament Configuration',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (isEditing)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primaryBlue.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.primaryBlue),
                        ),
                        child: Text(
                          'ID: ${_existingAuction!.id}',
                          style: const TextStyle(
                            color: AppColors.primaryBlue,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Tournament / Auction Name',
                    hintText: 'e.g. JP Champions League',
                    prefixIcon: Icon(Icons.emoji_events_outlined, color: AppColors.primaryBlue),
                  ),
                  validator: (v) => v == null || v.trim().isEmpty ? 'Name is required' : null,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _venueController,
                        decoration: const InputDecoration(
                          labelText: 'Venue / Location',
                          prefixIcon: Icon(Icons.location_on_outlined, color: AppColors.secondaryPurple),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: DropdownButtonFormField<AuctionMode>(
                        initialValue: _mode,
                        decoration: const InputDecoration(
                          labelText: 'Auction Mode',
                          prefixIcon: Icon(Icons.shuffle_rounded, color: AppColors.accentPink),
                        ),
                        items: AuctionMode.values.map((m) {
                          return DropdownMenuItem(
                            value: m,
                            child: Text(m.displayName),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _mode = val);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _descController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Description / Rules Note',
                    prefixIcon: Icon(Icons.notes_rounded, color: AppColors.textSecondary),
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Financial Rules (Indian Rupees ₹)',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _purseController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Team Total Purse (₹)',
                          prefixIcon: Icon(Icons.account_balance_wallet_outlined, color: AppColors.gold),
                        ),
                        validator: (v) => v == null || double.tryParse(v) == null ? 'Enter valid purse' : null,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        controller: _basePriceController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Default Base Price (₹)',
                          prefixIcon: Icon(Icons.currency_rupee_rounded, color: AppColors.primaryBlue),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        controller: _bidIncrementController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Bid Increment (₹)',
                          prefixIcon: Icon(Icons.trending_up_rounded, color: AppColors.success),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                const Text(
                  'Squad & Timer Limits',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _teamsController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Number of Teams',
                          prefixIcon: Icon(Icons.groups_outlined, color: AppColors.secondaryPurple),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        controller: _minSquadController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Min Squad Size',
                          prefixIcon: Icon(Icons.person_outline, color: AppColors.textSecondary),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        controller: _maxSquadController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Max Squad Size',
                          prefixIcon: Icon(Icons.group_add_outlined, color: AppColors.accentPink),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        controller: _countdownController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Hammer Timer (s)',
                          prefixIcon: Icon(Icons.timer_outlined, color: AppColors.warning),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 28),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton(
                      onPressed: () => context.go('/auctions'),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 14),
                    GradientButton(
                      onPressed: _isSaving ? null : _handleSave,
                      isLoading: _isSaving,
                      icon: isEditing ? Icons.save_rounded : Icons.check_circle_outline_rounded,
                      label: isEditing ? 'Save Changes' : 'Save & Activate Tournament',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
