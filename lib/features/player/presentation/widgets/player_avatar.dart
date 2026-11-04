import 'package:flutter/material.dart';
import 'package:jp_auction_arena/core/constants/app_colors.dart';
import 'package:jp_auction_arena/features/player/domain/models/player.dart';

class PlayerAvatar extends StatelessWidget {
  const PlayerAvatar({required this.player, this.size = 52, super.key});

  final Player player;
  final double size;

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: size / 2,
      backgroundColor: AppColors.softPurple,
      child: Text(
        _initials(player.name),
        style: TextStyle(
          color: AppColors.neonPink,
          fontWeight: FontWeight.w800,
          fontSize: size * 0.3,
        ),
      ),
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    return parts.length == 1
        ? parts.first.substring(0, 1).toUpperCase()
        : '${parts.first.substring(0, 1)}${parts.last.substring(0, 1)}'
              .toUpperCase();
  }
}
