import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:phosphor_icons/phosphor_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/theme/sg_colors.dart';
import '../../../core/theme/sg_spacing.dart';
import '../../../core/ui/sg_avatar.dart';
import '../../auth/data/auth_repository.dart';
import '../../feed/data/feed_repository.dart';
import '../../social/data/social_repository.dart';
import '../data/profile_repository.dart';
import '../domain/profile_validation.dart';
import '../domain/user_profile.dart';
import 'workout_gallery_section.dart';

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
          if (user != null) {
            ref.invalidate(socialProfileProvider(user.id));
            ref.invalidate(profileCheckinsProvider(user.id));
          }
          await ref.read(currentProfileProvider.future);
        },
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(SgSpacing.lg),
          children: <Widget>[
            Text(
              'Perfil',
              style: Theme.of(
                context,
              ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800),
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
    final username = profile.username == null
        ? '@usuario'
        : '@${profile.username}';
    final social = ref.watch(socialProfileProvider(profile.id));
    final checkins = ref.watch(profileCheckinsProvider(profile.id));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Card(
          child: Padding(
            padding: const EdgeInsets.all(SgSpacing.xl),
            child: Column(
              children: <Widget>[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    _EditableAvatar(profile: profile),
                    const SizedBox(width: SgSpacing.xl),
                    Expanded(
                      child: social.when(
                        loading: () => const SizedBox(
                          height: 48,
                          child: Center(child: CircularProgressIndicator()),
                        ),
                        error: (error, stackTrace) => const SizedBox.shrink(),
                        data: (value) => value == null
                            ? const SizedBox.shrink()
                            : Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: <Widget>[
                                  _ProfileStat(
                                    value: value.checkinCount,
                                    label: 'treinos',
                                  ),
                                  _ProfileStat(
                                    value: value.followerCount,
                                    label: 'seguidores',
                                  ),
                                  _ProfileStat(
                                    value: value.followingCount,
                                    label: 'seguindo',
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: SgSpacing.md),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    displayName,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(height: SgSpacing.xxs),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    username,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: SgColors.moonstone,
                      fontWeight: FontWeight.w700,
                    ),
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
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () async {
                      final saved = await showModalBottomSheet<bool>(
                        context: context,
                        isScrollControlled: true,
                        useSafeArea: true,
                        builder: (_) => _EditProfileSheet(profile: profile),
                      );
                      if (saved == true) {
                        ref.invalidate(currentProfileProvider);
                        ref.invalidate(socialProfileProvider(profile.id));
                      }
                    },
                    icon: const Icon(Icons.edit_outlined),
                    label: Text(
                      profile.isConfigured
                          ? 'Editar perfil'
                          : 'Configurar perfil',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: SgSpacing.xl),
        checkins.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stackTrace) => const _ProfileMessage(
            message: 'Não foi possível carregar seu histórico de treinos.',
          ),
          data: (items) => items.isEmpty
              ? const _ProfileMessage(
                  message: 'Seus check-ins aparecerão aqui.',
                )
              : WorkoutGallerySection(items: items),
        ),
      ],
    );
  }
}

enum _AvatarAction { camera, gallery, remove }

class _EditableAvatar extends ConsumerStatefulWidget {
  const _EditableAvatar({required this.profile});

  final UserProfile profile;

  @override
  ConsumerState<_EditableAvatar> createState() => _EditableAvatarState();
}

class _EditableAvatarState extends ConsumerState<_EditableAvatar> {
  bool _busy = false;

  String get _label =>
      widget.profile.displayName ?? widget.profile.username ?? 'Atleta SnapGym';

  Future<void> _openActions() async {
    if (_busy) return;

    final action = await showModalBottomSheet<_AvatarAction>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Tirar foto'),
              onTap: () => Navigator.pop(context, _AvatarAction.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Escolher da galeria'),
              onTap: () => Navigator.pop(context, _AvatarAction.gallery),
            ),
            if (widget.profile.avatarKey != null)
              ListTile(
                leading: const Icon(Icons.delete_outline),
                title: const Text('Remover foto'),
                onTap: () => Navigator.pop(context, _AvatarAction.remove),
              ),
            const SizedBox(height: SgSpacing.sm),
          ],
        ),
      ),
    );

    if (action == null || !mounted) return;
    if (action == _AvatarAction.remove) {
      await _remove();
      return;
    }

    final source = action == _AvatarAction.camera
        ? ImageSource.camera
        : ImageSource.gallery;
    final image = await ImagePicker().pickImage(
      source: source,
      maxWidth: 1800,
      maxHeight: 1800,
    );
    if (image == null || !mounted) return;
    await _upload(image.path);
  }

  Future<void> _upload(String path) async {
    setState(() => _busy = true);
    try {
      await ref.read(profileRepositoryProvider).updateAvatar(path);
      _refreshIdentity();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Não foi possível atualizar sua foto.')),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _remove() async {
    setState(() => _busy = true);
    try {
      await ref.read(profileRepositoryProvider).removeAvatar();
      _refreshIdentity();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Não foi possível remover sua foto.')),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _refreshIdentity() {
    ref.invalidate(currentProfileProvider);
    ref.invalidate(socialProfileProvider(widget.profile.id));
    ref.invalidate(profileCheckinsProvider(widget.profile.id));
    ref.invalidate(feedCheckinsProvider);
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Alterar foto do perfil',
      child: InkWell(
        onTap: _openActions,
        customBorder: const CircleBorder(),
        child: Stack(
          clipBehavior: Clip.none,
          children: <Widget>[
            Opacity(
              opacity: _busy ? 0.55 : 1,
              child: SgAvatar(
                label: _label,
                avatarKey: widget.profile.avatarKey,
                radius: 46,
              ),
            ),
            Positioned(
              right: -2,
              bottom: -2,
              child: Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Theme.of(context).colorScheme.surface,
                    width: 2,
                  ),
                ),
                child: _busy
                    ? const Padding(
                        padding: EdgeInsets.all(7),
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(
                        Icons.camera_alt_rounded,
                        size: 16,
                        color: Theme.of(context).colorScheme.onPrimary,
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileStat extends StatelessWidget {
  const _ProfileStat({required this.value, required this.label});

  final int value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Text(
          '$value',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
        ),
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: SgColors.darkTextSecondary),
        ),
      ],
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
    _usernameController = TextEditingController(
      text: widget.profile.username ?? '',
    );
    _displayNameController = TextEditingController(
      text: widget.profile.displayName ?? '',
    );
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
      await ref
          .read(profileRepositoryProvider)
          .updateOwnProfile(
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
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
                  helperText:
                      '3–24 caracteres; letras, números, ponto e underline',
                ),
              ),
              const SizedBox(height: SgSpacing.md),
              TextFormField(
                controller: _displayNameController,
                validator: (value) =>
                    ProfileValidation.displayName(value ?? ''),
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

class _ProfileMessage extends StatelessWidget {
  const _ProfileMessage({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(SgSpacing.xl),
        child: Text(message, textAlign: TextAlign.center),
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
            TextButton(
              onPressed: onRetry,
              child: const Text('Tentar novamente'),
            ),
          ],
        ),
      ),
    );
  }
}
