import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:jp_auction_arena/core/constants/app_colors.dart';
import 'package:jp_auction_arena/features/tournament/domain/models/tournament.dart';
import 'package:jp_auction_arena/features/tournament/domain/models/tournament_status.dart';
import 'package:jp_auction_arena/features/tournament/presentation/providers/tournament_providers.dart';

/// Form screen for both Creating a new tournament and Editing an existing one.
class TournamentFormScreen extends ConsumerStatefulWidget {
  final String? tournamentId;

  const TournamentFormScreen({
    super.key,
    this.tournamentId,
  });

  bool get isEditing => tournamentId != null && tournamentId!.isNotEmpty;

  @override
  ConsumerState<TournamentFormScreen> createState() => _TournamentFormScreenState();
}

class _TournamentFormScreenState extends ConsumerState<TournamentFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _shortNameController;
  late final TextEditingController _seasonController;
  late final TextEditingController _cityController;
  late final TextEditingController _venueController;
  late final TextEditingController _maxTeamsController;

  DateTime _startDate = DateTime.now().add(const Duration(days: 7));
  DateTime _endDate = DateTime.now().add(const Duration(days: 21));
  TournamentStatus _status = TournamentStatus.draft;

  bool _isLoadingInitial = false;
  bool _isSubmitting = false;
  String? _loadError;
  Tournament? _existingTournament;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _shortNameController = TextEditingController();
    _seasonController = TextEditingController(text: DateTime.now().year.toString());
    _cityController = TextEditingController();
    _venueController = TextEditingController();
    _maxTeamsController = TextEditingController(text: '8');

    if (widget.isEditing) {
      _loadExistingTournament();
    }
  }

  Future<void> _loadExistingTournament() async {
    setState(() {
      _isLoadingInitial = true;
      _loadError = null;
    });

    try {
      final repo = ref.read(tournamentRepositoryProvider);
      final tournament = await repo.getTournamentById(widget.tournamentId!);

      if (tournament != null) {
        _existingTournament = tournament;
        _nameController.text = tournament.name;
        _shortNameController.text = tournament.shortName;
        _seasonController.text = tournament.seasonYear;
        _cityController.text = tournament.city;
        _venueController.text = tournament.venue;
        _maxTeamsController.text = tournament.maxTeams.toString();
        _startDate = tournament.startDate;
        _endDate = tournament.endDate;
        _status = tournament.status;
      } else {
        _loadError = 'Tournament not found.';
      }
    } catch (e) {
      _loadError = 'Failed to load tournament: $e';
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingInitial = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _shortNameController.dispose();
    _seasonController.dispose();
    _cityController.dispose();
    _venueController.dispose();
    _maxTeamsController.dispose();
    super.dispose();
  }

  Future<void> _pickDate({required bool isStart}) async {
    final initialDate = isStart ? _startDate : _endDate;
    final firstDate = isStart
        ? DateTime(2020)
        : _startDate; // End date cannot be before start date
    final lastDate = DateTime(2035);

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate.isBefore(firstDate) ? firstDate : initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
                  primary: AppColors.primaryNavy,
                  onPrimary: Colors.white,
                  surface: Theme.of(context).brightness == Brightness.dark
                      ? AppColors.darkSurface
                      : Colors.white,
                ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
          if (_endDate.isBefore(_startDate)) {
            _endDate = _startDate.add(const Duration(days: 7));
          }
        } else {
          _endDate = picked;
        }
      });
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_endDate.isBefore(_startDate)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('End date cannot be earlier than start date.'),
          backgroundColor: AppColors.danger,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final now = DateTime.now();
      final tournament = Tournament(
        id: widget.isEditing ? widget.tournamentId! : '',
        name: _nameController.text.trim(),
        shortName: _shortNameController.text.trim().toUpperCase(),
        seasonYear: _seasonController.text.trim(),
        startDate: _startDate,
        endDate: _endDate,
        city: _cityController.text.trim(),
        venue: _venueController.text.trim(),
        maxTeams: int.parse(_maxTeamsController.text.trim()),
        status: _status,
        createdAt: _existingTournament?.createdAt ?? now,
        updatedAt: now,
      );

      if (widget.isEditing) {
        await ref.read(tournamentListProvider.notifier).updateTournament(tournament);
      } else {
        await ref.read(tournamentListProvider.notifier).createTournament(tournament);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.isEditing
                  ? 'Tournament "${tournament.name}" updated successfully!'
                  : 'Tournament "${tournament.name}" created successfully!',
            ),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving tournament: $e'),
            backgroundColor: AppColors.danger,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd MMM yyyy');

    if (_isLoadingInitial) {
      return Scaffold(
        appBar: AppBar(title: const Text('Loading Tournament...')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_loadError != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Error')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: AppColors.danger),
              const SizedBox(height: 12),
              Text(_loadError!),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => context.pop(),
                child: const Text('Go Back'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.isEditing ? 'Edit Tournament' : 'Create Tournament',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              children: [
                // Tournament Identity Section
                _buildSectionHeader('Tournament Details'),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Tournament Name *',
                    hintText: 'e.g. Gujarat Premier Cricket League 2026',
                    prefixIcon: Icon(Icons.emoji_events_outlined),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a tournament name';
                    }
                    if (value.trim().length < 3) {
                      return 'Tournament name must be at least 3 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: TextFormField(
                        controller: _shortNameController,
                        decoration: const InputDecoration(
                          labelText: 'Short Name *',
                          hintText: 'e.g. GPCL 2026',
                          prefixIcon: Icon(Icons.tag),
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Enter short code';
                          }
                          if (value.trim().length < 2 || value.trim().length > 12) {
                            return 'Between 2 - 12 chars';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 1,
                      child: TextFormField(
                        controller: _seasonController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Season / Year *',
                          hintText: '2026',
                          prefixIcon: Icon(Icons.calendar_month_outlined),
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Required';
                          }
                          final year = int.tryParse(value.trim());
                          if (year == null || year < 2000 || year > 2100) {
                            return 'Valid year';
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Location & Venue Section
                _buildSectionHeader('Venue & Location'),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _cityController,
                        decoration: const InputDecoration(
                          labelText: 'City *',
                          hintText: 'e.g. Ahmedabad',
                          prefixIcon: Icon(Icons.location_city_outlined),
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) =>
                            value == null || value.trim().isEmpty ? 'Please enter city' : null,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 2,
                      child: TextFormField(
                        controller: _venueController,
                        decoration: const InputDecoration(
                          labelText: 'Venue / Stadium *',
                          hintText: 'e.g. Narendra Modi Stadium',
                          prefixIcon: Icon(Icons.stadium_outlined),
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) =>
                            value == null || value.trim().isEmpty ? 'Please enter venue' : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Schedule & Team Limits
                _buildSectionHeader('Schedule & Configuration'),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () => _pickDate(isStart: true),
                        borderRadius: BorderRadius.circular(8),
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Start Date *',
                            prefixIcon: Icon(Icons.date_range),
                            border: OutlineInputBorder(),
                          ),
                          child: Text(dateFormat.format(_startDate)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: InkWell(
                        onTap: () => _pickDate(isStart: false),
                        borderRadius: BorderRadius.circular(8),
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'End Date *',
                            prefixIcon: Icon(Icons.event),
                            border: OutlineInputBorder(),
                          ),
                          child: Text(dateFormat.format(_endDate)),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _maxTeamsController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Maximum Teams *',
                          hintText: 'e.g. 8',
                          prefixIcon: Icon(Icons.groups_outlined),
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter teams count';
                          }
                          final n = int.tryParse(value.trim());
                          if (n == null || n < 2 || n > 32) {
                            return 'Enter between 2 and 32 teams';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: DropdownButtonFormField<TournamentStatus>(
                        key: ValueKey(_status),
                        initialValue: _status,
                        decoration: const InputDecoration(
                          labelText: 'Status *',
                          prefixIcon: Icon(Icons.flag_outlined),
                          border: OutlineInputBorder(),
                        ),
                        items: TournamentStatus.values.map((s) {
                          return DropdownMenuItem(
                            value: s,
                            child: Row(
                              children: [
                                Icon(s.icon, size: 16, color: s.color),
                                const SizedBox(width: 8),
                                Text(s.label),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() {
                              _status = val;
                            });
                          }
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                // Form Actions
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton(
                      onPressed: _isSubmitting ? null : () => context.pop(),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 16),
                    FilledButton.icon(
                      onPressed: _isSubmitting ? null : _submitForm,
                      icon: _isSubmitting
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.check),
                      label: Text(
                        widget.isEditing ? 'Save Changes' : 'Create Tournament',
                      ),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primaryNavy,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
            color: AppColors.lightBlueAccent,
          ),
        ),
        const SizedBox(height: 4),
        const Divider(),
      ],
    );
  }
}
