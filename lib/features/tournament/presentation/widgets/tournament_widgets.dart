import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:jp_auction_arena/core/constants/app_colors.dart';
import 'package:jp_auction_arena/core/theme/app_spacing.dart';
import 'package:jp_auction_arena/features/tournament/domain/models/tournament.dart';
import 'package:jp_auction_arena/features/tournament/domain/models/tournament_status.dart';
import 'package:jp_auction_arena/shared/widgets/app_card.dart';

String tournamentDateRange(Tournament tournament) {
  final formatter = DateFormat.yMMMd();
  return '${formatter.format(tournament.startDate)} - '
      '${formatter.format(tournament.endDate)}';
}

class TournamentStatusChip extends StatelessWidget {
  const TournamentStatusChip({required this.status, super.key});

  final TournamentStatus status;

  @override
  Widget build(BuildContext context) => Chip(
    avatar: CircleAvatar(radius: 5, backgroundColor: _color(status)),
    label: Text(status.label),
    visualDensity: VisualDensity.compact,
  );

  Color _color(TournamentStatus status) => switch (status) {
    TournamentStatus.draft => AppColors.softPurple,
    TournamentStatus.upcoming => AppColors.electricBlue,
    TournamentStatus.active => AppColors.success,
    TournamentStatus.completed => AppColors.warning,
    TournamentStatus.archived => AppColors.secondaryText,
    TournamentStatus.cancelled => AppColors.error,
  };
}

class TournamentListCard extends StatelessWidget {
  const TournamentListCard({
    required this.tournament,
    required this.onOpen,
    this.onEdit,
    super.key,
  });

  final Tournament tournament;
  final VoidCallback onOpen;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) => AppCard(
    onTap: onOpen,
    padding: const EdgeInsets.all(AppSpacing.md),
    child: Row(
      children: [
        CircleAvatar(
          radius: 25,
          backgroundColor: Theme.of(
            context,
          ).colorScheme.surfaceContainerHighest,
          child: tournament.logoReference == null
              ? Icon(
                  Icons.emoji_events_outlined,
                  color: Theme.of(context).colorScheme.tertiary,
                )
              : const Icon(Icons.image_outlined),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                tournament.name,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                '${tournament.city} · ${tournament.seasonYear} · '
                '${tournamentDateRange(tournament)}',
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                '${tournament.format} · ${tournament.maxTeams} teams',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        TournamentStatusChip(status: tournament.status),
        if (onEdit != null)
          IconButton(
            tooltip: 'Edit ${tournament.name}',
            onPressed: onEdit,
            icon: const Icon(Icons.edit_outlined),
          )
        else
          const Icon(Icons.chevron_right),
      ],
    ),
  );
}

class TournamentField extends StatelessWidget {
  const TournamentField({
    required this.controller,
    required this.label,
    this.validator,
    this.keyboardType,
    this.maxLines = 1,
    this.hintText,
    super.key,
  });

  final TextEditingController controller;
  final String label;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final int maxLines;
  final String? hintText;

  @override
  Widget build(BuildContext context) => TextFormField(
    controller: controller,
    validator: validator,
    keyboardType: keyboardType,
    maxLines: maxLines,
    decoration: InputDecoration(labelText: label, hintText: hintText),
  );
}

class TournamentDateField extends StatelessWidget {
  const TournamentDateField({
    required this.label,
    required this.value,
    required this.onTap,
    this.errorText,
    super.key,
  });

  final String label;
  final DateTime? value;
  final VoidCallback onTap;
  final String? errorText;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(12),
    child: InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        errorText: errorText,
        suffixIcon: const Icon(Icons.calendar_today_outlined),
      ),
      child: Text(
        value == null ? 'Select date' : DateFormat.yMMMd().format(value!),
      ),
    ),
  );
}
