import 'package:flutter/material.dart';
import 'package:jp_auction_arena/core/constants/app_colors.dart';

enum PlayerStatus {
  available,
  sold,
  unsold;

  String get label => switch (this) {
    PlayerStatus.available => 'Available',
    PlayerStatus.sold => 'Sold',
    PlayerStatus.unsold => 'Unsold',
  };

  Color get color => switch (this) {
    PlayerStatus.available => AppColors.electricBlue,
    PlayerStatus.sold => AppColors.success,
    PlayerStatus.unsold => AppColors.neonPink,
  };

  IconData get icon => switch (this) {
    PlayerStatus.available => Icons.person_search_outlined,
    PlayerStatus.sold => Icons.check_circle_outline,
    PlayerStatus.unsold => Icons.remove_circle_outline,
  };
}
