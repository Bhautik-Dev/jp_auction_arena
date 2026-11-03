import 'package:flutter/material.dart';
import 'package:jp_auction_arena/core/constants/app_colors.dart';
import 'package:jp_auction_arena/features/team/domain/models/team.dart';

class TeamLogoView extends StatelessWidget {
  const TeamLogoView({required this.team, this.size = 48, super.key});

  final Team team;
  final double size;

  @override
  Widget build(BuildContext context) {
    final logo = team.logo;
    return Container(
      width: size,
      height: size,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Color(team.primaryColorValue).withAlpha(35),
        borderRadius: BorderRadius.circular(size * 0.28),
        border: Border.all(color: Color(team.primaryColorValue).withAlpha(110)),
      ),
      alignment: Alignment.center,
      child: logo == null
          ? Icon(
              Icons.shield_outlined,
              size: size * 0.56,
              color: Color(team.primaryColorValue),
            )
          : Image.memory(
              logo.bytes,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Icon(
                Icons.broken_image_outlined,
                color: AppColors.muted,
                size: size * 0.56,
              ),
            ),
    );
  }
}
