import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_colors.dart';
import '../../core/connection/connection_service.dart';

/// Compact online/offline indicator used in the AppBar and sidebar.
///
/// Shows a colored dot plus a short label. On mobile only the dot is shown
/// to keep the limited AppBar real estate for actions.
class ConnectionIndicator extends ConsumerWidget {
  const ConnectionIndicator({
    super.key,
    this.showLabel = true,
    this.compact = false,
  });

  /// Whether to render the textual label next to the dot.
  final bool showLabel;

  /// When true, only the colored dot is rendered (mobile AppBar).
  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(connectionStatusProvider).when(
          data: (s) => s,
          error: (_, __) => ConnectionStatus.unknown,
          loading: () => ConnectionStatus.unknown,
        );

    final color = switch (status) {
      ConnectionStatus.wifi => AppColors.success,
      ConnectionStatus.mobile => AppColors.info,
      ConnectionStatus.none => AppColors.error,
      ConnectionStatus.unknown => AppColors.textMuted,
    };

    final label = switch (status) {
      ConnectionStatus.wifi => 'Online',
      ConnectionStatus.mobile => 'Mobile',
      ConnectionStatus.none => 'Offline',
      ConnectionStatus.unknown => 'Unknown',
    };

    if (compact) {
      return Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.5),
              blurRadius: 6,
              spreadRadius: 1,
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.4), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.5),
                  blurRadius: 6,
                  spreadRadius: 1,
                ),
              ],
            ),
          ),
          if (showLabel) ...[
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ],
      ),
    );
  }
}