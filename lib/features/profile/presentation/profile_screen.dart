import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/theme/sg_colors.dart';
import '../../../core/theme/sg_spacing.dart';
import '../../auth/data/auth_repository.dart';
import '../data/profile_repository.dart';
import '../domain/profile_validation.dart';
import '../domain/user_profile.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(currentProfileProvider);
    final user = ref.watch(authRepositoryProvider).currentUser;

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(currentProfileProvider);
          await ref.read(currentProfileProvider.future);
        },
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(SgSpacing.lg),
          children: <Widget>[
            Text(
              'Perfil',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: SgSpacing.xl),
            profile.when(
              data: (value) => value == null
                  ? const _ProfileUnavailable()
                  : _ProfileContent(profile: value, email: user?.email),
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(SgSpacing.xxxl),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (error, stackTrace) => _ProfileError(
                onRetry: () => ref.invalidate(currentProfileProvider),
              ),
            ),
            const SizedBox(height: SgSpacing.xl),
            OutlinedButton.icon(
              onPressed: () async {
                await ref.read(authRepositoryProvider).signOut();
              },
              icon: const Icon(Icons.logout_rounded),
              label: const Text('Sair'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileContent extends ConsumerWidget {
  const _ProfileContent({required this.profile, required this.email});

  final UserProfile profile;
  final String? email;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final displayName = profile.displayName ?? 'Complete seu perfil';
    final username = profile.username == null ? '@usuario' : '@${profile.username}';
    final initial = profile.displayName?.trim().isNotEmpty == true
        ? profile.displayName!.trim().characters.first.toUpperCase()
        : 'S';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(SgSpacing.xl),
        child: Column(
          children: <Widget>[
            CircleAvatar(
              radius: 42,
              backgroundColor: SgColors.orange,
              foregroundColor: SgColors.jet,
              child: Text(
                initial,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: SgColors.jet,
                    ),
              ),
            ),
            const SizedBox(height: SgSpacing.md),
            Text(
              displayName,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: SgSpacing.xxs),
            Text(
              username,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: SgColors.moonstone,
                    fontWeight: FontWeight.w700,
                  ),
            ),
            if (profile.bio != null) ...<Widget>[
              const SizedBox(height: SgSpacing.md),
              Text(
                profile.bio!,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
            if (email != null) ...<Widget>[
              const SizedBox(height: SgSpacing.lg),
              Text(
                email!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ],
            const SizedBox(height: SgSpacing.xl),
            FilledButton.icon(
              onPressed: () async {
                final saved = await showModalBottomSheet<bool>(
                  context: context,
                  isScrollControlled: true,
                  useSafeArea: true,
                  builder: (_) => _EditProfileSheet(profile: profile),
                );
                if (saved == true) {
                  ref.invalidate(currentProfileProvider);
                }
              },
              icon: const Icon(Icons.edit_outlined),
              label: Text(profile.isConfigured ? 'Editar perfil' : 'Configurar perfil'),
            ),
          ],
        ),
      ),
    );
  }
}

class _EditProfileSheet extends ConsumerStatefulWidget {
  const _EditProfileSheet({required this.profile});

  final UserProfile profile;

  @override
  ConsumerState<_EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends ConsumerState<_EditProfileSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _usernameController;
  late final TextEditingController _displayNameController;
  late final TextEditingController _bioController;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _usernameController = TextEditingController(text: widget.profile.username ?? '');
    _displayNameController = TextEditingController(text: widget.profile.displayName ?? '');
    _bioController = TextEditingController(text: widget.profile.bio ?? '');
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _displayNameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate() || _saving) return;
    setState(() => _saving = true);

    try {
      await ref.read(profileRepositoryProvider).updateOwnProfile(
            username: _usernameController.text,
            displayName: _displayNameController.text,
            bio: _bioController.text,
          );
      if (mounted) Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      var message = 'Não foi possível salvar o perfil.';
      if (error is PostgrestException && error.code == '23505') {
        message = 'Esse nome de usuário já está em uso.';
      }
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: SgSpacing.xl,
        right: SgSpacing.xl,
        top: SgSpacing.xl,
        bottom: MediaQuery.viewInsetsOf(context).bottom + SgSpacing.xl,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Text(
                'Seu perfil',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: SgSpacing.xl),
              TextFormField(
                controller: _usernameController,
                autocorrect: false,
                textCapitalization: TextCapitalization.none,
                validator: (value) => ProfileValidation.username(value ?? ''),
                decoration: const InputDecoration(
                  labelText: 'Nome de usuário',
                  prefixText: '@',
                  helperText: '3–24 caracteres; letras, números, ponto e underline',
                ),
              ),
              const SizedBox(height: SgSpacing.md),
              TextFormField(
                controller: _displayNameController,
                validator: (value) => ProfileValidation.displayName(value ?? ''),
                decoration: const InputDecoration(labelText: 'Nome exibido'),
              ),
              const SizedBox(height: SgSpacing.md),
              TextFormField(
                controller: _bioController,
                maxLines: 3,
                maxLength: 160,
                validator: (value) => ProfileValidation.bio(value ?? ''),
                decoration: const InputDecoration(labelText: 'Bio'),
              ),
              const SizedBox(height: SgSpacing.lg),
              FilledButton(
                onPressed: _saving ? null : _save,
                child: Text(_saving ? 'Salvando...' : 'Salvar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileUnavailable extends StatelessWidget {
  const _ProfileUnavailable();

  @override
  Widget build(BuildContext context) {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(SgSpacing.xl),
        child: Text('Perfil não encontrado para esta conta.'),
      ),
    );
  }
}

class _ProfileError extends StatelessWidget {
  const _ProfileError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(SgSpacing.xl),
        child: Column(
          children: <Widget>[
            const Text('Não foi possível carregar seu perfil.'),
            const SizedBox(height: SgSpacing.md),
            TextButton(onPressed: onRetry, child: const Text('Tentar novamente')),
          ],
        ),
      ),
    );
  }
}
