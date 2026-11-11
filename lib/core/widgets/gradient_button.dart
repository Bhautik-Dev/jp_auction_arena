import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../theme/app_theme.dart';

class GradientButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final Widget? child;
  final String? label;
  final IconData? icon;
  final double? width;
  final double height;
  final bool isLoading;
  final Gradient? gradient;

  const GradientButton({
    super.key,
    required this.onPressed,
    this.child,
    this.label,
    this.icon,
    this.width,
    this.height = 48,
    this.isLoading = false,
    this.gradient,
  }) : assert(child != null || label != null, 'Either child or label must be provided');

  @override
  Widget build(BuildContext context) {
    final effectiveGradient = onPressed == null
        ? LinearGradient(
            colors: [
              AppColors.textMuted.withValues(alpha: 0.3),
              AppColors.textMuted.withValues(alpha: 0.3),
            ],
          )
        : (gradient ?? AppColors.buttonGradient);

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        gradient: effectiveGradient,
        borderRadius: BorderRadius.circular(AppTheme.buttonRadius),
        boxShadow: onPressed != null
            ? [
                BoxShadow(
                  color: AppColors.secondaryPurple.withValues(alpha: 0.35),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppTheme.buttonRadius),
          onTap: isLoading ? null : onPressed,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : child ??
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (icon != null) ...[
                            Icon(icon, size: 18, color: Colors.white),
                            const SizedBox(width: 8),
                          ],
                          Flexible(
                            child: Text(
                              label!,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.3,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                        ],
                      ),
            ),
          ),
        ),
      ),
    );
  }
}
