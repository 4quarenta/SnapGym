import 'package:flutter/material.dart';

import '../../../core/theme/sg_spacing.dart';
import '../../../core/ui/sg_brand.dart';

class CheckinPlaceholderScreen extends StatelessWidget {
  const CheckinPlaceholderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(SgSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const SgBrand(fontSize: 28),
            const SizedBox(height: SgSpacing.xxl),
            Text(
              'Check-in',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: SgSpacing.xs),
            Text('Câmera, evidência e publicação de treino entrarão aqui.'),
          ],
        ),
      ),
    );
  }
}
