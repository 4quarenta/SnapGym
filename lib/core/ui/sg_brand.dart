import 'package:flutter/material.dart';

import '../theme/sg_colors.dart';

class SgBrand extends StatelessWidget {
  const SgBrand({
    super.key,
    this.fontSize = 32,
  });

  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.headlineMedium?.copyWith(
          fontSize: fontSize,
          fontWeight: FontWeight.w800,
          letterSpacing: -1.2,
        );

    return Text.rich(
      TextSpan(
        children: <InlineSpan>[
          TextSpan(text: 'Snap', style: style),
          TextSpan(
            text: 'Gym',
            style: style?.copyWith(color: SgColors.orange),
          ),
        ],
      ),
      semanticsLabel: 'SnapGym',
    );
  }
}
