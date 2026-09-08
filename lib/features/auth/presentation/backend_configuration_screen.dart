import 'package:flutter/material.dart';

import '../../../core/theme/sg_colors.dart';
import '../../../core/theme/sg_spacing.dart';
import '../../../core/ui/sg_brand.dart';

class BackendConfigurationScreen extends StatelessWidget {
  const BackendConfigurationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(SgSpacing.xl),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  const SgBrand(fontSize: 36),
                  const SizedBox(height: SgSpacing.xxl),
                  const Icon(
                    Icons.settings_ethernet_rounded,
                    size: 56,
                    color: SgColors.moonstone,
                  ),
                  const SizedBox(height: SgSpacing.lg),
                  Text(
                    'Backend não configurado',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: SgSpacing.sm),
                  Text(
                    'Este build precisa de SUPABASE_URL e SUPABASE_PUBLISHABLE_KEY. Builds de teste oficiais já recebem essas configurações automaticamente.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          height: 1.45,
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
