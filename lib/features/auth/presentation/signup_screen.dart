import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/sg_spacing.dart';
import '../../../core/ui/sg_primary_button.dart';
import '../data/auth_repository.dart';
import '../domain/auth_validation.dart';
import 'auth_error_message.dart';
import 'auth_form_scaffold.dart';

class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmationController = TextEditingController();
  bool _loading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmationController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _loading) return;

    setState(() => _loading = true);
    try {
      final response = await ref.read(authRepositoryProvider).signUp(
            email: _emailController.text,
            password: _passwordController.text,
          );
      if (!mounted) return;

      if (response.session == null) {
        context.go(
          '/auth/check-email?email=${Uri.encodeQueryComponent(_emailController.text.trim())}',
        );
      } else {
        context.go('/feed');
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(authErrorMessage(error))),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthFormScaffold(
      title: 'Crie sua conta',
      subtitle: 'A identidade social do perfil será configurada depois do primeiro acesso.',
      children: <Widget>[
        Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                autofillHints: const <String>[AutofillHints.newUsername],
                autocorrect: false,
                validator: (value) => AuthValidation.email(value ?? ''),
                decoration: const InputDecoration(
                  labelText: 'E-mail',
                  prefixIcon: Icon(Icons.alternate_email_rounded),
                ),
              ),
              const SizedBox(height: SgSpacing.md),
              TextFormField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                textInputAction: TextInputAction.next,
                autofillHints: const <String>[AutofillHints.newPassword],
                validator: (value) => AuthValidation.password(value ?? ''),
                decoration: InputDecoration(
                  labelText: 'Senha',
                  helperText: 'Mínimo de 8 caracteres',
                  prefixIcon: const Icon(Icons.lock_outline_rounded),
                  suffixIcon: IconButton(
                    onPressed: () => setState(
                      () => _obscurePassword = !_obscurePassword,
                    ),
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: SgSpacing.md),
              TextFormField(
                controller: _confirmationController,
                obscureText: true,
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _submit(),
                validator: (value) {
                  if (value != _passwordController.text) {
                    return 'As senhas não coincidem.';
                  }
                  return null;
                },
                decoration: const InputDecoration(
                  labelText: 'Confirmar senha',
                  prefixIcon: Icon(Icons.lock_reset_rounded),
                ),
              ),
              const SizedBox(height: SgSpacing.xl),
              SgPrimaryButton(
                label: _loading ? 'Criando conta...' : 'Criar conta',
                onPressed: _loading ? null : _submit,
              ),
            ],
          ),
        ),
        const SizedBox(height: SgSpacing.md),
        TextButton(
          onPressed: _loading ? null : () => context.go('/auth/login'),
          child: const Text('Já tem uma conta? Entrar'),
        ),
      ],
    );
  }
}
