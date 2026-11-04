import 'package:flutter/material.dart';
import 'package:jp_auction_arena/shared/widgets/app_text_field.dart';

class AppSearchField extends StatelessWidget {
  const AppSearchField({
    required this.onChanged,
    this.hint = 'Search',
    super.key,
  });

  final ValueChanged<String> onChanged;
  final String hint;

  @override
  Widget build(BuildContext context) {
    return AppTextField(
      label: hint,
      hint: hint,
      prefixIcon: Icons.search,
      onChanged: onChanged,
    );
  }
}
