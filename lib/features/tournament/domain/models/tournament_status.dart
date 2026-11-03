import 'package:flutter/material.dart';
import 'package:jp_auction_arena/core/constants/app_colors.dart';

/// Status of a tournament in JP AUCTION ARENA.
enum TournamentStatus {
  draft,
  active,
  completed,
  archived;

  /// User-friendly English label.
  String get label {
    switch (this) {
      case TournamentStatus.draft:
        return 'Draft';
      case TournamentStatus.active:
        return 'Active';
      case TournamentStatus.completed:
        return 'Completed';
      case TournamentStatus.archived:
        return 'Archived';
    }
  }

  /// Distinct theme-aligned badge color for high visibility.
  Color get color {
    switch (this) {
      case TournamentStatus.draft:
        return AppColors.warning;
      case TournamentStatus.active:
        return AppColors.success;
      case TournamentStatus.completed:
        return AppColors.primaryBlueAccent;
      case TournamentStatus.archived:
        return const Color(0xFF64748B);
    }
  }

  /// Status icon for visual identification.
  IconData get icon {
    switch (this) {
      case TournamentStatus.draft:
        return Icons.edit_note_outlined;
      case TournamentStatus.active:
        return Icons.play_circle_outline;
      case TournamentStatus.completed:
        return Icons.check_circle_outline;
      case TournamentStatus.archived:
        return Icons.archive_outlined;
    }
  }

  /// Whether tournament is currently active.
  bool get isActive => this == TournamentStatus.active;

  /// Whether tournament is in draft stage.
  bool get isDraft => this == TournamentStatus.draft;

  /// Whether tournament is completed.
  bool get isCompleted => this == TournamentStatus.completed;

  /// Whether tournament has been archived.
  bool get isArchived => this == TournamentStatus.archived;

  /// Whether the admin can activate this tournament.
  bool get canActivate => this == TournamentStatus.draft || this == TournamentStatus.archived;

  /// Whether the admin can deactivate this tournament back to draft.
  bool get canDeactivate => this == TournamentStatus.active;

  /// Whether the admin can archive this tournament.
  bool get canArchive => this != TournamentStatus.archived;

  /// Parse from string name safely.
  static TournamentStatus fromString(String? value) {
    if (value == null) return TournamentStatus.draft;
    return TournamentStatus.values.firstWhere(
      (s) => s.name.toLowerCase() == value.toLowerCase().trim(),
      orElse: () => TournamentStatus.draft,
    );
  }
}
