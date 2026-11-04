import 'package:flutter/material.dart';
import 'package:jp_auction_arena/core/theme/app_spacing.dart';

class ResponsivePageContainer extends StatelessWidget {
  const ResponsivePageContainer({
    required this.child,
    this.maxWidth = 1440,
    this.padding,
    super.key,
  });

  final Widget child;
  final double maxWidth;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) => SizedBox(
      width: constraints.maxWidth,
      height: constraints.maxHeight,
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: Padding(
            padding: padding ?? const EdgeInsets.all(AppSpacing.lg),
            child: child,
          ),
        ),
      ),
    ),
  );
}
