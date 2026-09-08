import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_icons/phosphor_icons.dart';

import '../../../core/config/app_config.dart';
import '../../../core/theme/sg_colors.dart';
import '../../../core/theme/sg_radius.dart';
import '../../../core/theme/sg_spacing.dart';
import '../../../core/ui/sg_brand.dart';
import '../../../core/ui/sg_primary_button.dart';

class FeedPlaceholderScreen extends ConsumerWidget {
  const FeedPlaceholderScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = ref.watch(appConfigProvider);
    final textTheme = Theme.of(context).textTheme;

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(SgSpacing.lg),
        children: <Widget>[
          Row(
            children: <Widget>[
              const Expanded(child: SgBrand()),
              _EnvironmentBadge(label: config.environment.label),
            ],
          ),
          const SizedBox(height: SgSpacing.xxl),
          Text(
            'Fundação pronta.',
            style: textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w800,
              letterSpacing: -0.8,
            ),
          ),
          const SizedBox(height: SgSpacing.xs),
          Text(
            'A partir daqui, cada feature entra sobre uma base única de tema, navegação e configuração.',
            style: textTheme.bodyLarge?.copyWith(
              color: SgColors.darkTextSecondary,
              height: 1.45,
            ),
          ),
          const SizedBox(height: SgSpacing.xl),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(SgSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'SnapGym UI v0.1',
                    style: textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: SgSpacing.md),
                  const Row(
                    children: <Widget>[
                      Expanded(
                        child: _ColorSwatch(
                          label: 'Orange',
                          value: '#F06021',
                          color: SgColors.orange,
                        ),
                      ),
                      SizedBox(width: SgSpacing.sm),
                      Expanded(
                        child: _ColorSwatch(
                          label: 'Moonstone',
                          value: '#6B9CAA',
                          color: SgColors.moonstone,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: SgSpacing.sm),
                  const _ColorSwatch(
                    label: 'Jet',
                    value: '#202123',
                    color: SgColors.jet,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: SgSpacing.lg),
          SgPrimaryButton(
            label: 'Fazer check-in',
            icon: const PhosphorIcon(PhosphorIconsBold.camera),
            onPressed: () {},
          ),
          const SizedBox(height: SgSpacing.sm),
          Text(
            config.hasSupabaseConfiguration
                ? 'Supabase configurado para este ambiente.'
                : 'Supabase ainda não configurado — o app pode iniciar normalmente.',
            style: textTheme.bodySmall?.copyWith(
              color: SgColors.darkTextSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _EnvironmentBadge extends StatelessWidget {
  const _EnvironmentBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: SgColors.moonstone.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(SgRadius.pill),
        border: Border.all(
          color: SgColors.moonstone.withValues(alpha: 0.45),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: SgSpacing.sm,
          vertical: SgSpacing.xs,
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: SgColors.moonstone,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.8,
              ),
        ),
      ),
    );
  }
}

class _ColorSwatch extends StatelessWidget {
  const _ColorSwatch({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final isOrange = color == SgColors.orange;
    final foreground = isOrange ? SgColors.jet : Colors.white;

    return Container(
      constraints: const BoxConstraints(minHeight: 94),
      padding: const EdgeInsets.all(SgSpacing.md),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(SgRadius.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.end,
        children: <Widget>[
          Text(
            label,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: foreground,
                  fontWeight: FontWeight.w800,
                ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: foreground.withValues(alpha: 0.82),
                ),
          ),
        ],
      ),
    );
  }
}
