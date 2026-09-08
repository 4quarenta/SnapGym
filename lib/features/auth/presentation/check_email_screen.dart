import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/sg_colors.dart';
import '../../../core/theme/sg_spacing.dart';
import '../../../core/ui/sg_brand.dart';

class CheckEmailScreen extends StatelessWidget {
  const CheckEmailScreen({required this.email, super.key});

  final String? email;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(SgSpacing.xl),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  const SgBrand(fontSize: 36),
                  const SizedBox(height: SgSpacing.xxxl),
                  const Icon(
                    Icons.mark_email_read_outlined,
                    size: 64,
                    color: SgColors.moonstone,
                  ),
                  const SizedBox(height: SgSpacing.xl),
                  Text(
                    'Confirme seu e-mail',
                    textAlign: TextAlign.center,
                    style: textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: SgSpacing.sm),
                  Text(
                    email == null || email!.isEmpty
                        ? 'Enviamos um link de confirmação para o e-mail informado.'
                        : 'Enviamos um link de confirmação para $email.',
                    textAlign: TextAlign.center,
                    style: textTheme.bodyLarge?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: SgSpacing.md),
                  Text(
                    'Depois de confirmar, volte ao app e faça login.',
                    textAlign: TextAlign.center,
                    style: textTheme.bodyMedium,
                  ),
                  const SizedBox(height: SgSpacing.xl),
                  FilledButton(
                    onPressed: () => context.go('/auth/login'),
                    child: const Text('Voltar para o login'),
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
