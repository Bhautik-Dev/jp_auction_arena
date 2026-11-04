import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:jp_auction_arena/features/auction/domain/errors/auction_exceptions.dart';
import 'package:jp_auction_arena/features/auction/domain/models/auction.dart';
import 'package:jp_auction_arena/features/auction/domain/models/auction_status.dart';
import 'package:jp_auction_arena/features/auction/domain/models/auction_type.dart';
import 'package:jp_auction_arena/features/auction/domain/models/cricket_format.dart';
import 'package:jp_auction_arena/features/auction/presentation/providers/auction_providers.dart';
import 'package:jp_auction_arena/core/routing/route_names.dart';
import 'package:jp_auction_arena/features/auth/application/auth_providers.dart';
import 'package:jp_auction_arena/features/dashboard/application/dashboard_providers.dart';
import 'package:jp_auction_arena/shared/widgets/app_states.dart';

class AuctionFormScreen extends ConsumerWidget {
  const AuctionFormScreen({this.auctionId, super.key});

  final String? auctionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (auctionId == null) return const _AuctionForm();
    final auction = ref.watch(auctionByIdProvider(auctionId!));
    return auction.when(
      loading: () => const AppLoadingIndicator(label: 'Loading auction...'),
      error: (error, stackTrace) => AppErrorState(
        error: error,
        onRetry: () => ref.invalidate(auctionByIdProvider(auctionId!)),
      ),
      data: (value) => _AuctionForm(auction: value),
    );
  }
}

class _AuctionForm extends ConsumerStatefulWidget {
  const _AuctionForm({this.auction});

  final Auction? auction;

  @override
  ConsumerState<_AuctionForm> createState() => _AuctionFormState();
}

class _AuctionFormState extends ConsumerState<_AuctionForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _description;
  late final TextEditingController _logo;
  late final TextEditingController _location;
  late final TextEditingController _customFormat;
  late final TextEditingController _maxTeams;
  late final TextEditingController _maxPlayers;
  late final TextEditingController _minPlayers;
  late final TextEditingController _purse;
  late final TextEditingController _currency;
  late final TextEditingController _organizer;
  late final TextEditingController _contact;
  late DateTime _date;
  late int _startTimeMinutes;
  late AuctionType _type;
  late CricketFormat _format;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final auction = widget.auction;
    _name = TextEditingController(text: auction?.name ?? '');
    _description = TextEditingController(text: auction?.description ?? '');
    _logo = TextEditingController(text: auction?.logoReference ?? '');
    _location = TextEditingController(text: auction?.location ?? '');
    _customFormat = TextEditingController(text: auction?.customFormat ?? '');
    _maxTeams = TextEditingController(text: '${auction?.maxTeams ?? 8}');
    _maxPlayers = TextEditingController(
      text: '${auction?.maxPlayersPerTeam ?? 18}',
    );
    _minPlayers = TextEditingController(
      text: '${auction?.minPlayersPerTeam ?? 11}',
    );
    _purse = TextEditingController(
      text: '${auction?.totalPursePerTeam ?? 10000000}',
    );
    _currency = TextEditingController(text: auction?.baseCurrency ?? 'INR');
    _organizer = TextEditingController(text: auction?.organizerName ?? '');
    _contact = TextEditingController(text: auction?.contactDetails ?? '');
    _date = auction?.auctionDate ?? DateTime.now().add(const Duration(days: 7));
    _startTimeMinutes = auction?.startTimeMinutes ?? 600;
    _type = auction?.auctionType ?? AuctionType.liveAuction;
    _format = auction?.cricketFormat ?? CricketFormat.t20;
  }

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    _logo.dispose();
    _location.dispose();
    _customFormat.dispose();
    _maxTeams.dispose();
    _maxPlayers.dispose();
    _minPlayers.dispose();
    _purse.dispose();
    _currency.dispose();
    _organizer.dispose();
    _contact.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(20),
    children: [
      Text(
        widget.auction == null ? 'Create Auction' : 'Edit Auction',
        style: Theme.of(context).textTheme.headlineMedium,
      ),
      const SizedBox(height: 8),
      const Text(
        'Configure the auction event and per-team purse and squad limits. '
        'Team/player registration and bidding rules are separate future modules.',
      ),
      const SizedBox(height: 20),
      Form(
        key: _formKey,
        child: Column(
          children: [
            _text(_name, 'Auction Name', required: true),
            _text(_logo, 'Auction Logo / Image reference (optional)'),
            _text(_description, 'Auction Description', maxLines: 3),
            _datePicker(context),
            _timePicker(context),
            _text(_location, 'Auction Location (optional)'),
            DropdownButtonFormField<AuctionType>(
              initialValue: _type,
              decoration: const InputDecoration(labelText: 'Auction Type'),
              items: [
                for (final type in AuctionType.values)
                  DropdownMenuItem(value: type, child: Text(type.label)),
              ],
              onChanged: (value) => setState(() => _type = value!),
            ),
            const SizedBox(height: 14),
            DropdownButtonFormField<CricketFormat>(
              initialValue: _format,
              decoration: const InputDecoration(labelText: 'Cricket Format'),
              items: [
                for (final format in CricketFormat.values)
                  DropdownMenuItem(value: format, child: Text(format.label)),
              ],
              onChanged: (value) => setState(() => _format = value!),
            ),
            if (_format == CricketFormat.custom) ...[
              const SizedBox(height: 14),
              _text(_customFormat, 'Custom Cricket Format', required: true),
            ],
            const SizedBox(height: 14),
            _text(
              _maxTeams,
              'Maximum Number of Teams',
              required: true,
              numeric: true,
            ),
            _text(
              _maxPlayers,
              'Maximum Players Per Team',
              required: true,
              numeric: true,
            ),
            _text(
              _minPlayers,
              'Minimum Players Per Team',
              required: true,
              numeric: true,
            ),
            _text(
              _purse,
              'Total Auction Purse Per Team',
              required: true,
              numeric: true,
            ),
            _text(_currency, 'Base Currency (3-letter code)', required: true),
            DropdownButtonFormField<AuctionStatus>(
              initialValue: widget.auction?.status ?? AuctionStatus.draft,
              decoration: const InputDecoration(
                labelText: 'Auction Status',
                helperText: 'Change status from Auction Details.',
              ),
              items: [
                for (final status in AuctionStatus.values)
                  DropdownMenuItem(value: status, child: Text(status.label)),
              ],
              onChanged: null,
            ),
            const SizedBox(height: 14),
            _text(_organizer, 'Organizer Name', required: true),
            _text(_contact, 'Contact Details (optional)'),
            const SizedBox(height: 20),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.icon(
                onPressed: _saving ? null : _submit,
                icon: _saving
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save_outlined),
                label: Text(
                  widget.auction == null ? 'Create Auction' : 'Save Changes',
                ),
              ),
            ),
          ],
        ),
      ),
    ],
  );

  Widget _text(
    TextEditingController controller,
    String label, {
    bool required = false,
    bool numeric = false,
    int maxLines = 1,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: numeric
          ? const TextInputType.numberWithOptions(decimal: true)
          : null,
      decoration: InputDecoration(labelText: label),
      validator: (value) {
        if (required && (value == null || value.trim().isEmpty)) {
          return '$label is required.';
        }
        if (numeric && value != null && value.trim().isNotEmpty) {
          final parsed = double.tryParse(value);
          if (parsed == null || !parsed.isFinite) {
            return 'Enter a valid number.';
          }
        }
        return null;
      },
    ),
  );

  Widget _datePicker(BuildContext context) => Material(
    color: Theme.of(context).colorScheme.surface,
    child: ListTile(
      contentPadding: EdgeInsets.zero,
      title: const Text('Auction Date'),
      subtitle: Text(MaterialLocalizations.of(context).formatFullDate(_date)),
      trailing: const Icon(Icons.calendar_today_outlined),
      onTap: () async {
        final today = DateTime.now();
        final value = await showDatePicker(
          context: context,
          initialDate: _date.isBefore(today) ? today : _date,
          firstDate: DateTime(today.year, today.month, today.day),
          lastDate: DateTime(today.year + 20),
        );
        if (value != null) {
          setState(() => _date = value);
        }
      },
    ),
  );

  Widget _timePicker(BuildContext context) => Material(
    color: Theme.of(context).colorScheme.surface,
    child: ListTile(
      contentPadding: EdgeInsets.zero,
      title: const Text('Auction Start Time'),
      subtitle: Text(
        TimeOfDay(
          hour: _startTimeMinutes ~/ 60,
          minute: _startTimeMinutes % 60,
        ).format(context),
      ),
      trailing: const Icon(Icons.schedule_outlined),
      onTap: () async {
        final value = await showTimePicker(
          context: context,
          initialTime: TimeOfDay(
            hour: _startTimeMinutes ~/ 60,
            minute: _startTimeMinutes % 60,
          ),
        );
        if (value != null) {
          setState(() => _startTimeMinutes = value.hour * 60 + value.minute);
        }
      },
    ),
  );

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final session = ref
        .read(authSessionProvider)
        .whenOrNull(data: (value) => value);
    if (session == null) return;
    setState(() => _saving = true);
    try {
      final now = DateTime.now();
      final previous = widget.auction;
      final auction = Auction(
        id: previous?.id ?? '',
        name: _name.text.trim(),
        logoReference: _logo.text.trim().isEmpty ? null : _logo.text.trim(),
        description: _description.text.trim(),
        auctionDate: _date,
        startTimeMinutes: _startTimeMinutes,
        location: _location.text.trim(),
        auctionType: _type,
        cricketFormat: _format,
        customFormat: _format == CricketFormat.custom
            ? _customFormat.text.trim()
            : null,
        maxTeams: int.parse(_maxTeams.text),
        maxPlayersPerTeam: int.parse(_maxPlayers.text),
        minPlayersPerTeam: int.parse(_minPlayers.text),
        totalPursePerTeam: double.parse(_purse.text),
        baseCurrency: _currency.text.trim().toUpperCase(),
        status: previous?.status ?? AuctionStatus.draft,
        organizerName: _organizer.text.trim(),
        contactDetails: _contact.text.trim(),
        createdAt: previous?.createdAt ?? now,
        updatedAt: now,
      );
      final service = ref.read(auctionManagementServiceProvider);
      final saved = previous == null
          ? await service.create(session.user, auction)
          : await service.update(session.user, auction);
      if (previous == null) {
        ref.read(authSessionProvider.notifier).assignAuction(saved.id);
      }
      _invalidate(saved.id);
      if (mounted) context.go(RouteNames.auctionDetailPath(saved.id));
    } on AuctionException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.message)));
      }
    } on FormatException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Invalid numeric value: ${error.message}')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _invalidate(String id) {
    ref.invalidate(auctionsProvider);
    ref.invalidate(auctionHistoryProvider);
    ref.invalidate(auctionByIdProvider(id));
    ref.invalidate(dashboardSnapshotProvider);
  }
}
