import 'package:flutter/material.dart';
import 'package:jp_auction_arena/core/responsive/app_breakpoints.dart';

/// Centers page content and applies consistent width-aware spacing.
class ResponsiveContent extends StatelessWidget {
  const ResponsiveContent({
    required this.child,
    this.maxWidth = AppBreakpoints.contentMaxWidth,
    super.key,
  });

  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final horizontalPadding = constraints.maxWidth < AppBreakpoints.compact
            ? 16.0
            : 24.0;
        final verticalPadding = constraints.maxWidth < AppBreakpoints.compact
            ? 24.0
            : 32.0;

        return Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: horizontalPadding,
                vertical: verticalPadding,
              ),
              child: child,
            ),
          ),
        );
      },
    );
  }
}
