import 'package:flutter/material.dart';
import 'package:jp_auction_arena/core/constants/app_colors.dart';

enum TeamStatus {
  active,
  inactive,
  archived;

  String get label => switch (this) {
    TeamStatus.active => 'Active',
    TeamStatus.inactive => 'Inactive',
    TeamStatus.archived => 'Archived',
  };

  Color get color => switch (this) {
    TeamStatus.active => AppColors.success,
    TeamStatus.inactive => AppColors.warning,
    TeamStatus.archived => AppColors.muted,
  };

  IconData get icon => switch (this) {
    TeamStatus.active => Icons.check_circle_outline,
    TeamStatus.inactive => Icons.pause_circle_outline,
    TeamStatus.archived => Icons.archive_outlined,
  };
}
