import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:jp_auction_arena/core/routing/route_names.dart';
import 'package:jp_auction_arena/core/theme/app_spacing.dart';
import 'package:jp_auction_arena/features/auction/domain/models/auction_status.dart';
import 'package:jp_auction_arena/features/auction/presentation/providers/auction_providers.dart';
import 'package:jp_auction_arena/features/auth/application/auth_providers.dart';
import 'package:jp_auction_arena/features/team/domain/errors/team_exceptions.dart';
import 'package:jp_auction_arena/features/team/domain/models/team.dart';
import 'package:jp_auction_arena/features/team/domain/models/team_status.dart';
import 'package:jp_auction_arena/features/team/presentation/providers/team_providers.dart';
import 'package:jp_auction_arena/shared/widgets/app_states.dart';

class TeamFormScreen extends ConsumerWidget {
  const TeamFormScreen({required this.auctionId, this.teamId, super.key});

  final String auctionId;
  final String? teamId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final params = teamId == null
        ? null
        : (auctionId: auctionId, teamId: teamId!);
    return ref
        .watch(auctionByIdProvider(auctionId))
        .when(
          loading: () => const AppLoadingIndicator(label: 'Loading auction...'),
          error: (error, stackTrace) => AppErrorState(
            error: error,
            onRetry: () => ref.invalidate(auctionByIdProvider(auctionId)),
          ),
          data: (auction) {
            final canEdit =
                auction.status == AuctionStatus.draft ||
                auction.status == AuctionStatus.ready;
            if (!canEdit) {
              return AppEmptyState(
                title: 'Team registration is locked',
                message:
                    'Teams cannot be created or edited after this auction becomes Live.',
                action: OutlinedButton(
                  onPressed: () =>
                      context.go(RouteNames.auctionTeamsPath(auctionId)),
                  child: const Text('Back to teams'),
                ),
              );
            }
            if (params == null) return _TeamForm(auctionId: auctionId);
            return ref
                .watch(teamForEditProvider(params))
                .when(
                  loading: () =>
                      const AppLoadingIndicator(label: 'Loading team...'),
                  error: (error, stackTrace) => AppErrorState(
                    error: error,
                    onRetry: () => ref.invalidate(teamForEditProvider(params)),
                  ),
                  data: (team) => team.status == TeamStatus.archived
                      ? AppEmptyState(
                          title: 'Archived team is read-only',
                          message:
                              'Restore this team before editing its information.',
                          action: OutlinedButton(
                            onPressed: () => context.go(
                              RouteNames.auctionTeamDetailPath(
                                auctionId,
                                team.id,
                              ),
                            ),
                            child: const Text('View team details'),
                          ),
                        )
                      : _TeamForm(auctionId: auctionId, team: team),
                );
          },
        );
  }
}

class _TeamForm extends ConsumerStatefulWidget {
  const _TeamForm({required this.auctionId, this.team});

  final String auctionId;
  final Team? team;

  @override
  ConsumerState<_TeamForm> createState() => _TeamFormState();
}

class _TeamFormState extends ConsumerState<_TeamForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _shortName;
  late final TextEditingController _logo;
  late final TextEditingController _owner;
  late final TextEditingController _manager;
  late final TextEditingController _phone;
  late final TextEditingController _email;
  late final TextEditingController _city;
  late final TextEditingController _description;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final team = widget.team;
    _name = TextEditingController(text: team?.name ?? '');
    _shortName = TextEditingController(text: team?.shortName ?? '');
    _logo = TextEditingController(text: team?.logoReference ?? '');
    _owner = TextEditingController(text: team?.ownerName ?? '');
    _manager = TextEditingController(text: team?.managerName ?? '');
    _phone = TextEditingController(text: team?.contactPhone ?? '');
    _email = TextEditingController(text: team?.contactEmail ?? '');
    _city = TextEditingController(text: team?.city ?? '');
    _description = TextEditingController(text: team?.description ?? '');
  }

  @override
  void dispose() {
    _name.dispose();
    _shortName.dispose();
    _logo.dispose();
    _owner.dispose();
    _manager.dispose();
    _phone.dispose();
    _email.dispose();
    _city.dispose();
    _description.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(AppSpacing.lg),
    children: [
      Text(
        widget.team == null ? 'Register Team' : 'Edit Team',
        style: Theme.of(context).textTheme.headlineMedium,
      ),
      const SizedBox(height: AppSpacing.sm),
      const Text(
        'Team purse and squad limits are inherited from this auction and are not configured per team.',
      ),
      const SizedBox(height: AppSpacing.lg),
      Form(
        key: _formKey,
        child: Column(
          children: [
            _field(_name, 'Team Name', required: true),
            _field(_shortName, 'Team Short Name', required: true),
            _field(_logo, 'Team Logo / Image reference (optional)'),
            _field(_owner, 'Team Owner Name', required: true),
            _field(_manager, 'Team Manager Name', required: true),
            _field(_phone, 'Contact Number'),
            _field(_email, 'Email', email: true),
            _field(_city, 'Team City'),
            _field(_description, 'Team Description', maxLines: 4),
            const SizedBox(height: AppSpacing.md),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.icon(
                onPressed: _saving ? null : _submit,
                icon: const Icon(Icons.save_outlined),
                label: Text(_saving ? 'Saving...' : 'Save Team'),
              ),
            ),
          ],
        ),
      ),
    ],
  );

  Widget _field(
    TextEditingController controller,
    String label, {
    bool required = false,
    bool email = false,
    int maxLines = 1,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: AppSpacing.md),
    child: TextFormField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(labelText: label),
      validator: (value) {
        final text = value?.trim() ?? '';
        if (required && text.isEmpty) return '$label is required.';
        if (email &&
            text.isNotEmpty &&
            !RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(text)) {
          return 'Enter a valid email address.';
        }
        return null;
      },
    ),
  );

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final session = await ref.read(authSessionProvider.future);
    if (session == null) return;
    setState(() => _saving = true);
    final previous = widget.team;
    final now = DateTime.now();
    final team = Team(
      id: previous?.id ?? '',
      auctionId: widget.auctionId,
      name: _name.text.trim(),
      shortName: _shortName.text.trim(),
      primaryColorValue: previous?.primaryColorValue ?? 0xFF418BFF,
      secondaryColorValue: previous?.secondaryColorValue ?? 0xFFAA8BFF,
      ownerName: _owner.text.trim(),
      managerName: _manager.text.trim(),
      contactPhone: _phone.text.trim(),
      contactEmail: _email.text.trim(),
      city: _city.text.trim(),
      description: _description.text.trim(),
      logoReference: _logo.text.trim().isEmpty ? null : _logo.text.trim(),
      status: previous?.status ?? TeamStatus.active,
      createdAt: previous?.createdAt ?? now,
      updatedAt: now,
      hasAuctionActivity: previous?.hasAuctionActivity ?? false,
      hasPlayerAssignments: previous?.hasPlayerAssignments ?? false,
    );
    try {
      final saved = previous == null
          ? await ref
                .read(teamManagementServiceProvider)
                .create(session.user, team)
          : await ref
                .read(teamManagementServiceProvider)
                .update(session.user, team);
      ref.invalidate(teamsForAuctionProvider(widget.auctionId));
      ref.invalidate(
        teamByIdProvider((auctionId: widget.auctionId, teamId: saved.id)),
      );
      if (mounted) {
        context.go(
          RouteNames.auctionTeamDetailPath(widget.auctionId, saved.id),
        );
      }
    } on TeamException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.message)));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}
