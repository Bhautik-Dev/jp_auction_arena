import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/image_picker_helper.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/gradient_button.dart';
import '../../data/models/models.dart';
import '../../data/repositories/repositories.dart';

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
  int _currentStep = 0;
  final int _totalSteps = 6;
  bool _isSaving = false;
  bool _isAutoDraftSaved = false;
  String _auctionId = '';

  // Step 1: Tournament Info
  final _nameController = TextEditingController();
  final _venueController = TextEditingController();
  DateTime _startDate = DateTime.now().add(const Duration(days: 3));
  TimeOfDay _startTime = const TimeOfDay(hour: 10, minute: 0);
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _descController = TextEditingController();
  String? _logoBase64;

  // Step 1 Validation Errors
  String? _nameError;
  String? _venueError;
  String? _startDateError;
  String? _phoneError;
  String? _emailError;

  // Step 2: Auction Config (Categories & Per-category base price)
  final List<String> _categories = [
    'Batsman',
    'Bowler',
    'All-Rounder',
    'Wicket-Keeper',
  ];
  final Map<String, TextEditingController> _categoryBasePriceControllers = {};
  final _customCategoryController = TextEditingController();
  String? _categoryError;

  // Step 3: Auction Mode
  AuctionMode _selectedMode = AuctionMode.manual;

  // Step 4: Auction Settings
  final _teamsCountController = TextEditingController(text: '8');
  final _minSquadController = TextEditingController(text: '11');
  final _maxSquadController = TextEditingController(text: '15');
  final _defaultBasePriceController = TextEditingController(text: '10000');
  final _bidIncrementController = TextEditingController(text: '2000');
  final _teamPurseController = TextEditingController(text: '1000000');
  final _countdownController = TextEditingController(text: '30');
  bool _reservePurseRule = true;
  bool _smartBidSlabs = false;

  // Step 4 Validation Errors
  String? _teamsCountError;
  String? _squadError;
  String? _purseError;
  String? _basePriceError;
  String? _bidIncrementError;
  String? _countdownError;

  // Step 5: Teams Setup Table
  final List<_TeamDraftItem> _draftTeams = [];

  // Step 5 Add Team fields
  final _teamNameController = TextEditingController();
  final _teamOwnerController = TextEditingController();
  String? _teamLogoBase64;
  String? _teamTableError;

  @override
  void initState() {
    super.initState();
    _auctionId = widget.editAuctionId ?? 'auc_${DateTime.now().millisecondsSinceEpoch}';

    // Initialize per-category base price controllers
    for (final cat in _categories) {
      _categoryBasePriceControllers[cat] = TextEditingController(text: '10000');
    }

    if (widget.editAuctionId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _loadExistingAuction());
    }
  }

  void _loadExistingAuction() {
    final repo = ref.read(auctionRepositoryProvider);
    final a = repo.getById(widget.editAuctionId!);
    if (a != null) {
      setState(() {
        _nameController.text = a.name;
        _venueController.text = a.venue;
        _descController.text = a.description;
        _startDate = a.startDateTime;
        _startTime = TimeOfDay(hour: a.startDateTime.hour, minute: a.startDateTime.minute);
        _phoneController.text = a.contactPhone;
        _emailController.text = a.contactEmail;
        _logoBase64 = a.logoBase64;

        _categories.clear();
        _categories.addAll(a.categories);
        for (final cat in _categories) {
          final price = a.categoryBasePrices[cat] ?? a.basePriceDefault;
          _categoryBasePriceControllers[cat] = TextEditingController(text: price.toStringAsFixed(0));
        }

        _selectedMode = a.mode;
        _teamsCountController.text = a.numberOfTeams.toString();
        _minSquadController.text = a.minSquad.toString();
        _maxSquadController.text = a.maxSquad.toString();
        _defaultBasePriceController.text = a.basePriceDefault.toStringAsFixed(0);
        _bidIncrementController.text = a.bidIncrement.toStringAsFixed(0);
        _teamPurseController.text = a.teamPurse.toStringAsFixed(0);
        _countdownController.text = a.countdownSeconds.toString();
        _reservePurseRule = a.reservePurseRule;
        _smartBidSlabs = a.smartBidSlabs;

        // Load existing teams
        final teamRepo = ref.read(teamRepositoryProvider);
        final existingTeams = teamRepo.getByAuctionId(a.id);
        if (existingTeams.isNotEmpty) {
          _draftTeams.clear();
          for (final t in existingTeams) {
            _draftTeams.add(_TeamDraftItem(
              id: t.id,
              name: t.name,
              ownerName: t.ownerName,
              logoBase64: t.logoBase64,
            ));
          }
        }
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _venueController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _descController.dispose();
    _customCategoryController.dispose();
    _teamsCountController.dispose();
    _minSquadController.dispose();
    _maxSquadController.dispose();
    _defaultBasePriceController.dispose();
    _bidIncrementController.dispose();
    _teamPurseController.dispose();
    _countdownController.dispose();
    _teamNameController.dispose();
    _teamOwnerController.dispose();
    for (final c in _categoryBasePriceControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  // Auto-saves draft to Hive silently
  Future<void> _saveDraftAutomatically() async {
    final startDateTime = DateTime(
      _startDate.year,
      _startDate.month,
      _startDate.day,
      _startTime.hour,
      _startTime.minute,
    );

    final categoryBasePrices = <String, double>{};
    for (final entry in _categoryBasePriceControllers.entries) {
      categoryBasePrices[entry.key] = double.tryParse(entry.value.text.trim()) ??
          (double.tryParse(_defaultBasePriceController.text.trim()) ?? 10000);
    }

    final auction = Auction(
      id: _auctionId,
      name: _nameController.text.trim().isNotEmpty
          ? _nameController.text.trim()
          : 'Untitled Auction Draft',
      logoBase64: _logoBase64,
      venue: _venueController.text.trim(),
      description: _descController.text.trim(),
      startDateTime: startDateTime,
      status: AuctionStatus.draft,
      categories: _categories,
      numberOfTeams: int.tryParse(_teamsCountController.text.trim()) ?? 8,
      minSquad: int.tryParse(_minSquadController.text.trim()) ?? 11,
      maxSquad: int.tryParse(_maxSquadController.text.trim()) ?? 15,
      basePriceDefault: double.tryParse(_defaultBasePriceController.text.trim()) ?? 10000,
      bidIncrement: double.tryParse(_bidIncrementController.text.trim()) ?? 2000,
      teamPurse: double.tryParse(_teamPurseController.text.trim()) ?? 1000000,
      countdownSeconds: int.tryParse(_countdownController.text.trim()) ?? 30,
      mode: _selectedMode,
      contactPhone: _phoneController.text.trim(),
      contactEmail: _emailController.text.trim(),
      categoryBasePrices: categoryBasePrices,
      reservePurseRule: _reservePurseRule,
      smartBidSlabs: _smartBidSlabs,
    );

    await ref.read(auctionRepositoryProvider).save(auction);
    setState(() => _isAutoDraftSaved = true);
  }

  // Step Validations
  bool _validateStep(int step) {
    switch (step) {
      case 0: // Tournament Info
        bool isValid = true;
        setState(() {
          _nameError = null;
          _venueError = null;
          _startDateError = null;
          _phoneError = null;
          _emailError = null;

          if (_nameController.text.trim().isEmpty) {
            _nameError = 'Tournament name is required';
            isValid = false;
          }
          if (_venueController.text.trim().isEmpty) {
            _venueError = 'Venue is required';
            isValid = false;
          }

          // 10 digits validation for phone if entered
          final phone = _phoneController.text.replaceAll(RegExp(r'\D'), '');
          if (_phoneController.text.trim().isNotEmpty && phone.length != 10) {
            _phoneError = 'Contact phone must be exactly 10 digits (e.g. 9876543210)';
            isValid = false;
          }

          // Email validation if entered
          if (_emailController.text.trim().isNotEmpty &&
              !RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(_emailController.text.trim())) {
            _emailError = 'Please enter a valid email address';
            isValid = false;
          }
        });
        return isValid;

      case 1: // Auction Config
        if (_categories.isEmpty) {
          setState(() => _categoryError = 'At least one player category is required');
          return false;
        }
        setState(() => _categoryError = null);
        return true;

      case 2: // Auction Mode
        return true;

      case 3: // Auction Settings
        bool isValid = true;
        setState(() {
          _teamsCountError = null;
          _squadError = null;
          _purseError = null;
          _basePriceError = null;
          _bidIncrementError = null;
          _countdownError = null;

          final teamsCount = int.tryParse(_teamsCountController.text.trim());
          if (teamsCount == null || teamsCount < 2 || teamsCount > 32) {
            _teamsCountError = 'Number of teams must be between 2 and 32';
            isValid = false;
          }

          final minSquad = int.tryParse(_minSquadController.text.trim()) ?? 0;
          final maxSquad = int.tryParse(_maxSquadController.text.trim()) ?? 0;
          if (minSquad < 1 || maxSquad < minSquad) {
            _squadError = 'Max squad ($maxSquad) must be greater than or equal to Min squad ($minSquad)';
            isValid = false;
          }

          final purse = double.tryParse(_teamPurseController.text.trim());
          if (purse == null || purse <= 0) {
            _purseError = 'Team purse must be greater than 0';
            isValid = false;
          }

          final basePrice = double.tryParse(_defaultBasePriceController.text.trim());
          if (basePrice == null || basePrice <= 0) {
            _basePriceError = 'Default base price must be greater than 0';
            isValid = false;
          }

          final bidIncrement = double.tryParse(_bidIncrementController.text.trim());
          if (bidIncrement == null || bidIncrement <= 0) {
            _bidIncrementError = 'Bid increment must be greater than 0';
            isValid = false;
          }

          final countdown = int.tryParse(_countdownController.text.trim());
          if (countdown == null || countdown < 5 || countdown > 180) {
            _countdownError = 'Countdown timer must be between 5 and 180 seconds';
            isValid = false;
          }
        });
        return isValid;

      case 4: // Teams Setup
        if (_draftTeams.isEmpty) {
          setState(() => _teamTableError = 'Please add at least 2 teams before reviewing');
          return false;
        }
        final maxTeams = int.tryParse(_teamsCountController.text.trim()) ?? 8;
        if (_draftTeams.length > maxTeams) {
          setState(() => _teamTableError = 'You have added ${_draftTeams.length} teams, but maximum allowed is $maxTeams.');
          return false;
        }
        setState(() => _teamTableError = null);
        return true;

      case 5: // Review
        return true;

      default:
        return true;
    }
  }

  void _onNextStep() {
    if (_validateStep(_currentStep)) {
      _saveDraftAutomatically();
      if (_currentStep < _totalSteps - 1) {
        setState(() => _currentStep++);
      }
    }
  }

  void _onPrevStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    }
  }

  // Final Action: Create / Save Auction
  Future<void> _handleFinalizeAuction() async {
    setState(() => _isSaving = true);

    final startDateTime = DateTime(
      _startDate.year,
      _startDate.month,
      _startDate.day,
      _startTime.hour,
      _startTime.minute,
    );

    final categoryBasePrices = <String, double>{};
    for (final entry in _categoryBasePriceControllers.entries) {
      categoryBasePrices[entry.key] = double.tryParse(entry.value.text.trim()) ??
          (double.tryParse(_defaultBasePriceController.text.trim()) ?? 10000);
    }

    final auction = Auction(
      id: _auctionId,
      name: _nameController.text.trim(),
      logoBase64: _logoBase64,
      venue: _venueController.text.trim(),
      description: _descController.text.trim(),
      startDateTime: startDateTime,
      status: AuctionStatus.draft,
      categories: _categories,
      numberOfTeams: int.tryParse(_teamsCountController.text.trim()) ?? 8,
      minSquad: int.tryParse(_minSquadController.text.trim()) ?? 11,
      maxSquad: int.tryParse(_maxSquadController.text.trim()) ?? 15,
      basePriceDefault: double.tryParse(_defaultBasePriceController.text.trim()) ?? 10000,
      bidIncrement: double.tryParse(_bidIncrementController.text.trim()) ?? 2000,
      teamPurse: double.tryParse(_teamPurseController.text.trim()) ?? 1000000,
      countdownSeconds: int.tryParse(_countdownController.text.trim()) ?? 30,
      mode: _selectedMode,
      contactPhone: _phoneController.text.trim(),
      contactEmail: _emailController.text.trim(),
      categoryBasePrices: categoryBasePrices,
      reservePurseRule: _reservePurseRule,
      smartBidSlabs: _smartBidSlabs,
    );

    final auctionRepo = ref.read(auctionRepositoryProvider);
    await auctionRepo.save(auction);

    // Save Teams to Hive Team Repository
    final teamRepo = ref.read(teamRepositoryProvider);
    final totalPurse = double.tryParse(_teamPurseController.text.trim()) ?? 1000000;

    for (final t in _draftTeams) {
      final team = Team(
        id: t.id ?? 'team_${DateTime.now().millisecondsSinceEpoch}_${t.name.hashCode.abs() % 1000}',
        auctionId: _auctionId,
        name: t.name,
        ownerName: t.ownerName,
        logoBase64: t.logoBase64,
        purseTotal: totalPurse,
        purseSpent: 0,
      );
      await teamRepo.save(team);
    }

    ref.read(activeAuctionIdProvider.notifier).setAuctionId(_auctionId);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Auction "${auction.name}" and ${_draftTeams.length} franchise teams created!'),
          backgroundColor: AppColors.success,
        ),
      );
      context.go('/auctions');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Stepper Navigation Header
            _buildStepperHeader(),
            const SizedBox(height: 24),

            // Step Content Box
            GlassCard(
              padding: const EdgeInsets.all(28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildStepContent(),
                  const SizedBox(height: 32),
                  const Divider(color: AppColors.cardBorder),
                  const SizedBox(height: 20),
                  _buildNavigationButtons(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Stepper Header Bar with 6 Steps
  Widget _buildStepperHeader() {
    final steps = [
      {'title': 'Info', 'icon': Icons.info_outline_rounded},
      {'title': 'Config', 'icon': Icons.category_outlined},
      {'title': 'Mode', 'icon': Icons.shuffle_rounded},
      {'title': 'Settings', 'icon': Icons.tune_rounded},
      {'title': 'Teams', 'icon': Icons.groups_rounded},
      {'title': 'Review', 'icon': Icons.fact_check_outlined},
    ];

    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: AppColors.buttonGradient,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.sports_cricket_rounded, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    widget.editAuctionId != null
                        ? 'Edit Auction Wizard'
                        : '6-Step Create Auction Wizard',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              if (_isAutoDraftSaved)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.success.withValues(alpha: 0.5)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.cloud_done_outlined, color: AppColors.success, size: 14),
                      SizedBox(width: 6),
                      Text(
                        'Draft Auto-Saved to Hive',
                        style: TextStyle(
                          color: AppColors.success,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 18),
          LayoutBuilder(
            builder: (context, constraints) {
              final isSmall = constraints.maxWidth < 640;
              return Row(
                children: List.generate(steps.length, (index) {
                  final isDone = index < _currentStep;
                  final isCurrent = index == _currentStep;

                  Color dotColor = AppColors.textMuted;
                  if (isDone) dotColor = AppColors.success;
                  if (isCurrent) dotColor = AppColors.accentPink;

                  return Expanded(
                    child: InkWell(
                      onTap: () {
                        if (index < _currentStep || _validateStep(_currentStep)) {
                          _saveDraftAutomatically();
                          setState(() => _currentStep = index);
                        }
                      },
                      child: Row(
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: dotColor.withValues(alpha: 0.2),
                              border: Border.all(color: dotColor, width: 2),
                            ),
                            child: Center(
                              child: isDone
                                  ? const Icon(Icons.check_rounded, color: AppColors.success, size: 16)
                                  : Text(
                                      '${index + 1}',
                                      style: TextStyle(
                                        color: isCurrent ? Colors.white : dotColor,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                            ),
                          ),
                          if (!isSmall) ...[
                            const SizedBox(width: 8),
                            Text(
                              steps[index]['title'] as String,
                              style: TextStyle(
                                color: isCurrent ? Colors.white : AppColors.textSecondary,
                                fontSize: 12,
                                fontWeight: isCurrent ? FontWeight.bold : FontWeight.w500,
                              ),
                            ),
                          ],
                          if (index < steps.length - 1)
                            Expanded(
                              child: Container(
                                height: 2,
                                margin: const EdgeInsets.symmetric(horizontal: 8),
                                color: isDone ? AppColors.success : AppColors.cardBorder,
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                }),
              );
            },
          ),
        ],
      ),
    );
  }

  // Stepper Content Switcher
  Widget _buildStepContent() {
    switch (_currentStep) {
      case 0:
        return _buildStep1TournamentInfo();
      case 1:
        return _buildStep2AuctionConfig();
      case 2:
        return _buildStep3AuctionMode();
      case 3:
        return _buildStep4AuctionSettings();
      case 4:
        return _buildStep5TeamsSetup();
      case 5:
        return _buildStep6Review();
      default:
        return const SizedBox.shrink();
    }
  }

  // -------------------------------------------------------------
  // STEP 1: TOURNAMENT INFO
  // -------------------------------------------------------------
  Widget _buildStep1TournamentInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Step 1: Tournament Information',
          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 6),
        const Text(
          'Upload tournament logo, venue details, scheduled date & time, and contact info.',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
        ),
        const SizedBox(height: 24),

        // Logo Upload Row with Square Cropper Preview
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: AppColors.surfaceLight,
                border: Border.all(color: AppColors.cardBorder, width: 1.5),
              ),
              child: _logoBase64 != null && _logoBase64!.isNotEmpty
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(15),
                      child: Image.memory(
                        base64Decode(_logoBase64!),
                        fit: BoxFit.cover,
                      ),
                    )
                  : const Center(
                      child: Icon(Icons.sports_cricket_rounded, size: 40, color: AppColors.textMuted),
                    ),
            ),
            const SizedBox(width: 20),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                OutlinedButton.icon(
                  onPressed: () async {
                    final base64Image = await ImagePickerHelper.pickAndCropSquareImage(
                      context,
                      dialogTitle: 'Crop Tournament Logo (Square 1:1)',
                    );
                    if (base64Image != null) {
                      setState(() => _logoBase64 = base64Image);
                    }
                  },
                  icon: const Icon(Icons.image_rounded, size: 18),
                  label: Text(_logoBase64 != null ? 'Change Logo (Square)' : 'Upload Logo (Square Crop)'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primaryBlue,
                    side: const BorderSide(color: AppColors.primaryBlue),
                  ),
                ),
                if (_logoBase64 != null) ...[
                  const SizedBox(height: 6),
                  TextButton.icon(
                    onPressed: () => setState(() => _logoBase64 = null),
                    icon: const Icon(Icons.delete_outline, size: 16, color: AppColors.error),
                    label: const Text('Remove Logo', style: TextStyle(color: AppColors.error, fontSize: 12)),
                  ),
                ],
              ],
            ),
          ],
        ),
        const SizedBox(height: 24),

        // Tournament Name
        TextFormField(
          controller: _nameController,
          decoration: InputDecoration(
            labelText: 'Tournament Name *',
            hintText: 'e.g. Gujarat Premier Cricket Trophy 2026',
            prefixIcon: const Icon(Icons.emoji_events_outlined, color: AppColors.primaryBlue),
            errorText: _nameError,
          ),
          onChanged: (_) {
            if (_nameError != null) setState(() => _nameError = null);
          },
        ),
        const SizedBox(height: 16),

        // Venue
        TextFormField(
          controller: _venueController,
          decoration: InputDecoration(
            labelText: 'Venue / Stadium / City *',
            hintText: 'e.g. Narendra Modi Stadium Ground B, Ahmedabad',
            prefixIcon: const Icon(Icons.location_on_outlined, color: AppColors.secondaryPurple),
            errorText: _venueError,
          ),
          onChanged: (_) {
            if (_venueError != null) setState(() => _venueError = null);
          },
        ),
        const SizedBox(height: 16),

        // Date and Time Pickers
        Row(
          children: [
            Expanded(
              child: InkWell(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _startDate,
                    firstDate: DateTime.now().subtract(const Duration(days: 30)),
                    lastDate: DateTime.now().add(const Duration(days: 730)),
                  );
                  if (picked != null) {
                    setState(() => _startDate = picked);
                  }
                },
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: 'Start Date *',
                    prefixIcon: const Icon(Icons.calendar_today_rounded, color: AppColors.accentPink),
                    errorText: _startDateError,
                  ),
                  child: Text(
                    DateFormat('dd MMMM yyyy').format(_startDate),
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: InkWell(
                onTap: () async {
                  final picked = await showTimePicker(
                    context: context,
                    initialTime: _startTime,
                  );
                  if (picked != null) {
                    setState(() => _startTime = picked);
                  }
                },
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Start Time',
                    prefixIcon: Icon(Icons.access_time_rounded, color: AppColors.gold),
                  ),
                  child: Text(
                    _startTime.format(context),
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Contact Phone & Email
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                maxLength: 10,
                decoration: InputDecoration(
                  labelText: 'Contact Phone (10 digits validation)',
                  hintText: '9876543210',
                  counterText: '',
                  prefixIcon: const Icon(Icons.phone_outlined, color: AppColors.primaryBlue),
                  errorText: _phoneError,
                ),
                onChanged: (_) {
                  if (_phoneError != null) setState(() => _phoneError = null);
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: 'Contact Email',
                  hintText: 'admin@jpcricket.com',
                  prefixIcon: const Icon(Icons.email_outlined, color: AppColors.secondaryPurple),
                  errorText: _emailError,
                ),
                onChanged: (_) {
                  if (_emailError != null) setState(() => _emailError = null);
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Description
        TextFormField(
          controller: _descController,
          maxLines: 2,
          decoration: const InputDecoration(
            labelText: 'Tournament Description & Rules Memo',
            hintText: 'e.g. Official T20 tournament auction. All teams must field 2 under-19 players.',
            prefixIcon: Icon(Icons.notes_rounded, color: AppColors.textSecondary),
          ),
        ),
      ],
    );
  }

  // -------------------------------------------------------------
  // STEP 2: AUCTION CONFIG (CATEGORIES & PER-CATEGORY BASE PRICE)
  // -------------------------------------------------------------
  Widget _buildStep2AuctionConfig() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Step 2: Player Categories & Per-Category Base Price',
          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 6),
        const Text(
          'Configure player categories (chips) and set custom base prices for each category.',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
        ),
        const SizedBox(height: 20),

        // Category Chips
        const Text(
          'Player Categories:',
          style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: _categories.map((cat) {
            return Chip(
              backgroundColor: AppColors.surfaceLight,
              side: const BorderSide(color: AppColors.cardBorder),
              label: Text(cat, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
              deleteIcon: const Icon(Icons.close_rounded, size: 16, color: AppColors.accentPink),
              onDeleted: _categories.length > 1
                  ? () {
                      setState(() {
                        _categories.remove(cat);
                        _categoryBasePriceControllers.remove(cat);
                      });
                    }
                  : null,
            );
          }).toList(),
        ),
        if (_categoryError != null) ...[
          const SizedBox(height: 8),
          Text(_categoryError!, style: const TextStyle(color: AppColors.error, fontSize: 12)),
        ],
        const SizedBox(height: 16),

        // Add Custom Category input
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _customCategoryController,
                decoration: const InputDecoration(
                  labelText: 'Add Custom Category',
                  hintText: 'e.g. Icon Player, Emerging, Under-19, Overseas',
                  prefixIcon: Icon(Icons.add_circle_outline_rounded, color: AppColors.accentPink),
                ),
              ),
            ),
            const SizedBox(width: 12),
            GradientButton(
              onPressed: () {
                final newCat = _customCategoryController.text.trim();
                if (newCat.isNotEmpty && !_categories.contains(newCat)) {
                  setState(() {
                    _categories.add(newCat);
                    _categoryBasePriceControllers[newCat] = TextEditingController(
                      text: _defaultBasePriceController.text.trim().isNotEmpty
                          ? _defaultBasePriceController.text.trim()
                          : '10000',
                    );
                    _customCategoryController.clear();
                  });
                }
              },
              icon: Icons.add_rounded,
              label: 'Add Category',
            ),
          ],
        ),
        const SizedBox(height: 28),

        // Per-Category Base Price Slabs Table
        const Text(
          'Per-Category Base Prices (Indian Rupees ₹):',
          style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        const Text(
          'Set different reserve price floors for each category of players.',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
        ),
        const SizedBox(height: 14),

        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _categories.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            final cat = _categories[index];
            final controller = _categoryBasePriceControllers[cat] ??= TextEditingController(text: '10000');

            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.surfaceLight.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.primaryBlue.withValues(alpha: 0.2),
                    ),
                    child: Center(
                      child: Text(
                        '${index + 1}',
                        style: const TextStyle(color: AppColors.primaryBlue, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      cat,
                      style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                  ),
                  const SizedBox(width: 16),
                  SizedBox(
                    width: 180,
                    child: TextFormField(
                      controller: controller,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Base Price (₹)',
                        prefixIcon: Icon(Icons.currency_rupee_rounded, size: 16),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  // -------------------------------------------------------------
  // STEP 3: AUCTION MODE
  // -------------------------------------------------------------
  Widget _buildStep3AuctionMode() {
    final modes = [
      {
        'mode': AuctionMode.manual,
        'title': 'Manual Lot Selection',
        'desc': 'Auctioneer manually chooses and calls each player lot one by one to the podium.',
        'icon': Icons.pan_tool_alt_rounded,
        'gradient': const LinearGradient(colors: [Color(0xFF3B82F6), Color(0xFF2563EB)]),
      },
      {
        'mode': AuctionMode.auto,
        'title': 'Automatic Random Draw',
        'desc': 'The system randomly draws lots from the eligible cricket player pool automatically.',
        'icon': Icons.shuffle_rounded,
        'gradient': const LinearGradient(colors: [Color(0xFF8B5CF6), Color(0xFF7C3AED)]),
      },
      {
        'mode': AuctionMode.categoryWise,
        'title': 'Category-Wise Progression',
        'desc': 'Auction proceeds group by group: Marquee / Icon players first, Batsmen next, Bowlers, etc.',
        'icon': Icons.format_list_bulleted_rounded,
        'gradient': const LinearGradient(colors: [Color(0xFFEC4899), Color(0xFFDB2777)]),
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Step 3: Select Auction Mode',
          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 6),
        const Text(
          'Choose how player lots take the live bidding stage during hammer time.',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
        ),
        const SizedBox(height: 24),

        LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 720;
            return isWide
                ? Row(
                    children: modes.map((m) {
                      final mode = m['mode'] as AuctionMode;
                      final isSelected = _selectedMode == mode;
                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          child: _buildModeCard(m, isSelected),
                        ),
                      );
                    }).toList(),
                  )
                : Column(
                    children: modes.map((m) {
                      final mode = m['mode'] as AuctionMode;
                      final isSelected = _selectedMode == mode;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: _buildModeCard(m, isSelected),
                      );
                    }).toList(),
                  );
          },
        ),
      ],
    );
  }

  Widget _buildModeCard(Map<String, dynamic> m, bool isSelected) {
    final mode = m['mode'] as AuctionMode;

    return InkWell(
      onTap: () => setState(() => _selectedMode = mode),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.surfaceLight
              : AppColors.surfaceLight.withValues(alpha: 0.35),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.accentPink : AppColors.cardBorder,
            width: isSelected ? 2.0 : 1.0,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.accentPink.withValues(alpha: 0.25),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: m['gradient'] as Gradient,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(m['icon'] as IconData, color: Colors.white, size: 24),
                ),
                Icon(
                  isSelected ? Icons.check_circle_rounded : Icons.radio_button_off_rounded,
                  color: isSelected ? AppColors.accentPink : AppColors.textMuted,
                ),
              ],
            ),
            const SizedBox(height: 18),
            Text(
              m['title'] as String,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              m['desc'] as String,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // -------------------------------------------------------------
  // STEP 4: AUCTION SETTINGS
  // -------------------------------------------------------------
  Widget _buildStep4AuctionSettings() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Step 4: Auction Financials & Settings',
          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 6),
        const Text(
          'Configure team capacity, squad caps, hammer timer, and purse reserve rules.',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
        ),
        const SizedBox(height: 24),

        // Teams count & Squad sizes
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _teamsCountController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Number of Teams *',
                  prefixIcon: const Icon(Icons.groups_outlined, color: AppColors.primaryBlue),
                  errorText: _teamsCountError,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextFormField(
                controller: _minSquadController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Min Squad Size *',
                  prefixIcon: const Icon(Icons.person_outline, color: AppColors.secondaryPurple),
                  errorText: _squadError,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextFormField(
                controller: _maxSquadController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Max Squad Size *',
                  prefixIcon: Icon(Icons.group_add_outlined, color: AppColors.accentPink),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),

        // Purse & Base Prices
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _teamPurseController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Team Max Purse (₹) *',
                  prefixIcon: const Icon(Icons.account_balance_wallet_outlined, color: AppColors.gold),
                  errorText: _purseError,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextFormField(
                controller: _defaultBasePriceController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Default Base Price (₹) *',
                  prefixIcon: const Icon(Icons.currency_rupee_rounded, color: AppColors.primaryBlue),
                  errorText: _basePriceError,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextFormField(
                controller: _bidIncrementController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Default Bid Increment (₹) *',
                  prefixIcon: const Icon(Icons.trending_up_rounded, color: AppColors.success),
                  errorText: _bidIncrementError,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),

        // Countdown Timer
        SizedBox(
          width: 280,
          child: TextFormField(
            controller: _countdownController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Hammer Timer (seconds) *',
              prefixIcon: const Icon(Icons.timer_outlined, color: AppColors.warning),
              errorText: _countdownError,
            ),
          ),
        ),
        const SizedBox(height: 24),

        // NEW: Reserve Purse Rule Toggle
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surfaceLight.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: _reservePurseRule,
            activeThumbColor: AppColors.accentPink,
            activeTrackColor: AppColors.accentPink.withValues(alpha: 0.5),
            title: const Text(
              'Reserve Purse Rule (Safety Floor)',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
            ),
            subtitle: const Text(
              'A franchise must always retain enough purse to acquire its remaining minimum squad slots at default base price (Reserve = Base Price × Remaining Slots).',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
            ),
            onChanged: (val) => setState(() => _reservePurseRule = val),
          ),
        ),
        const SizedBox(height: 14),

        // NEW: Smart Bid Increment Slabs
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surfaceLight.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: _smartBidSlabs,
            activeThumbColor: AppColors.primaryBlue,
            activeTrackColor: AppColors.primaryBlue.withValues(alpha: 0.5),
            title: const Text(
              'Smart Bid Increment Slabs',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
            ),
            subtitle: const Text(
              'Automatically scales bid step by price range: +1K up to 10K, +2K up to 50K, +5K up to 2L, and +10K above 2L.',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
            ),
            onChanged: (val) => setState(() => _smartBidSlabs = val),
          ),
        ),
      ],
    );
  }

  // -------------------------------------------------------------
  // STEP 5: TEAMS SETUP (TABLE & ADD)
  // -------------------------------------------------------------
  Widget _buildStep5TeamsSetup() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Step 5: Franchise Teams Setup',
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  'Quickly configure all participating teams (${_draftTeams.length}/${_teamsCountController.text} teams added).',
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                ),
              ],
            ),
            OutlinedButton.icon(
              onPressed: () => _showAddTeamDialog(),
              icon: const Icon(Icons.group_add_rounded, size: 18),
              label: const Text('Add Team'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primaryBlue,
                side: const BorderSide(color: AppColors.primaryBlue),
              ),
            ),
          ],
        ),
        if (_teamTableError != null) ...[
          const SizedBox(height: 12),
          Text(_teamTableError!, style: const TextStyle(color: AppColors.error, fontSize: 13)),
        ],
        const SizedBox(height: 20),

        // Teams Table
        if (_draftTeams.isEmpty)
          const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 36),
              child: Text(
                'No teams added yet. Click "Add Team" to register your franchises.',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ),
          )
        else
          Container(
            decoration: BoxDecoration(
              color: AppColors.surfaceLight.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Table(
                columnWidths: const {
                  0: FixedColumnWidth(60),
                  1: FlexColumnWidth(2),
                  2: FlexColumnWidth(2),
                  3: FixedColumnWidth(90),
                },
                defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                children: [
                  TableRow(
                    decoration: BoxDecoration(color: AppColors.surfaceLight.withValues(alpha: 0.8)),
                    children: const [
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        child: Text('#', style: TextStyle(color: AppColors.textMuted, fontWeight: FontWeight.bold)),
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        child: Text('TEAM NAME', style: TextStyle(color: AppColors.textMuted, fontWeight: FontWeight.bold, fontSize: 11)),
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        child: Text('OWNER / CAPTAIN', style: TextStyle(color: AppColors.textMuted, fontWeight: FontWeight.bold, fontSize: 11)),
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        child: Text('ACTION', style: TextStyle(color: AppColors.textMuted, fontWeight: FontWeight.bold, fontSize: 11), textAlign: TextAlign.center),
                      ),
                    ],
                  ),
                  ..._draftTeams.asMap().entries.map((entry) {
                    final idx = entry.key;
                    final team = entry.value;

                    return TableRow(
                      decoration: BoxDecoration(
                        border: Border(bottom: BorderSide(color: AppColors.cardBorder.withValues(alpha: 0.5))),
                      ),
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          child: Text('${idx + 1}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 14,
                                backgroundColor: AppColors.primaryBlue.withValues(alpha: 0.3),
                                child: Text(
                                  team.name.isNotEmpty ? team.name[0].toUpperCase() : 'T',
                                  style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  team.name,
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          child: Text(
                            team.ownerName.isNotEmpty ? team.ownerName : 'Not Assigned',
                            style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          child: Center(
                            child: IconButton(
                              icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error, size: 18),
                              onPressed: () {
                                setState(() => _draftTeams.removeAt(idx));
                              },
                            ),
                          ),
                        ),
                      ],
                    );
                  }),
                ],
              ),
            ),
          ),
      ],
    );
  }

  void _showAddTeamDialog() {
    _teamNameController.clear();
    _teamOwnerController.clear();
    _teamLogoBase64 = null;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: AppColors.cardBorder, width: 1.2),
        ),
        title: const Text('Add Franchise Team', style: TextStyle(color: Colors.white)),
        content: SizedBox(
          width: 380,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _teamNameController,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'Team Name *',
                  hintText: 'e.g. Royal Kings XI',
                  prefixIcon: Icon(Icons.groups_rounded),
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _teamOwnerController,
                decoration: const InputDecoration(
                  labelText: 'Owner / Captain Name',
                  hintText: 'e.g. Suresh Raina',
                  prefixIcon: Icon(Icons.person_outline),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          GradientButton(
            height: 38,
            onPressed: () {
              final name = _teamNameController.text.trim();
              if (name.isEmpty) return;
              setState(() {
                _draftTeams.add(_TeamDraftItem(
                  name: name,
                  ownerName: _teamOwnerController.text.trim(),
                  logoBase64: _teamLogoBase64,
                ));
              });
              Navigator.pop(ctx);
            },
            label: 'Add to Table',
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------
  // STEP 6: REVIEW & SUMMARY
  // -------------------------------------------------------------
  Widget _buildStep6Review() {
    final purse = double.tryParse(_teamPurseController.text.trim()) ?? 1000000;
    final basePrice = double.tryParse(_defaultBasePriceController.text.trim()) ?? 10000;
    final bidInc = double.tryParse(_bidIncrementController.text.trim()) ?? 2000;
    final teamsCount = int.tryParse(_teamsCountController.text.trim()) ?? 8;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Step 6: Review Tournament Summary',
          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 6),
        const Text(
          'Review all tournament settings and franchise rosters before launching.',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
        ),
        const SizedBox(height: 24),

        // Summary Card
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.surfaceLight.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (_logoBase64 != null)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.memory(base64Decode(_logoBase64!), width: 50, height: 50, fit: BoxFit.cover),
                    )
                  else
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        gradient: AppColors.buttonGradient,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Center(child: Icon(Icons.sports_cricket, color: Colors.white)),
                    ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _nameController.text.trim(),
                          style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          '${_venueController.text.trim()} • Starts: ${DateFormat("dd MMM yyyy, hh:mm a").format(DateTime(_startDate.year, _startDate.month, _startDate.day, _startTime.hour, _startTime.minute))}',
                          style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Divider(color: AppColors.cardBorder),
              const SizedBox(height: 14),

              Wrap(
                spacing: 24,
                runSpacing: 14,
                children: [
                  _buildSummaryItem('Auction Mode', _selectedMode.displayName),
                  _buildSummaryItem('Franchise Purse', formatRupee(purse)),
                  _buildSummaryItem('Default Base Price', formatRupee(basePrice)),
                  _buildSummaryItem('Bid Increment', formatRupee(bidInc)),
                  _buildSummaryItem('Squad Size Range', '${_minSquadController.text} - ${_maxSquadController.text} Players'),
                  _buildSummaryItem('Hammer Timer', '${_countdownController.text}s'),
                  _buildSummaryItem('Reserve Purse Rule', _reservePurseRule ? 'Enabled (Active)' : 'Disabled'),
                  _buildSummaryItem('Smart Bid Slabs', _smartBidSlabs ? 'Enabled (+1K to +10K)' : 'Fixed (+${formatShort(bidInc)})'),
                  _buildSummaryItem('Teams Registered', '${_draftTeams.length} / $teamsCount teams'),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
      ],
    );
  }

  // Bottom Navigation Buttons (Back, Cancel, Next, Create)
  Widget _buildNavigationButtons() {
    final isLastStep = _currentStep == _totalSteps - 1;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            OutlinedButton(
              onPressed: () => context.go('/auctions'),
              child: const Text('Cancel'),
            ),
            if (_currentStep > 0) ...[
              const SizedBox(width: 12),
              OutlinedButton.icon(
                onPressed: _onPrevStep,
                icon: const Icon(Icons.arrow_back_rounded, size: 16),
                label: const Text('Back'),
              ),
            ],
          ],
        ),
        Row(
          children: [
            if (!isLastStep)
              GradientButton(
                onPressed: _onNextStep,
                icon: Icons.arrow_forward_rounded,
                label: 'Next Step',
              )
            else
              GradientButton(
                onPressed: _isSaving ? null : _handleFinalizeAuction,
                isLoading: _isSaving,
                icon: Icons.check_circle_rounded,
                label: widget.editAuctionId != null ? 'Update Tournament' : 'Create Auction & Launch',
              ),
          ],
        ),
      ],
    );
  }
}

class _TeamDraftItem {
  String? id;
  String name;
  String ownerName;
  String? logoBase64;

  _TeamDraftItem({
    this.id,
    required this.name,
    required this.ownerName,
    this.logoBase64,
  });
}
