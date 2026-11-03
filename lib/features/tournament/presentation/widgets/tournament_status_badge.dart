import 'package:flutter/material.dart';
import 'package:jp_auction_arena/features/tournament/domain/models/tournament_status.dart';

/// Clean high-contrast status badge representing tournament state.
class TournamentStatusBadge extends StatelessWidget {
  final TournamentStatus status;
  final bool isCompact;

  const TournamentStatusBadge({
    super.key,
    required this.status,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = status.color;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 8 : 12,
        vertical: isCompact ? 4 : 6,
      ),
      decoration: BoxDecoration(
        color: color.withAlpha(35),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withAlpha(120),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            status.icon,
            size: isCompact ? 12 : 14,
            color: color,
          ),
          const SizedBox(width: 6),
          Text(
            status.label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: isCompact ? 11 : 12,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}
