import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../storage/media_storage.dart';
import '../supabase/supabase_client_provider.dart';
import '../theme/sg_colors.dart';

class SgAvatar extends ConsumerWidget {
  const SgAvatar({
    required this.label,
    super.key,
    this.avatarKey,
    this.radius = 24,
  });

  final String label;
  final String? avatarKey;
  final double radius;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final client = ref.watch(supabaseClientProvider);
    final objectKey = avatarKey?.trim();
    final fallback = _FallbackAvatar(label: label, radius: radius);

    if (client == null || objectKey == null || objectKey.isEmpty) {
      return fallback;
    }

    final url = client.storage
        .from(MediaStorage.profileBucket)
        .getPublicUrl(objectKey);

    return Semantics(
      image: true,
      label: 'Foto de $label',
      child: ClipOval(
        child: Image.network(
          url,
          width: radius * 2,
          height: radius * 2,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => fallback,
          loadingBuilder: (context, child, progress) {
            if (progress == null) return child;
            return SizedBox(
              width: radius * 2,
              height: radius * 2,
              child: const DecoratedBox(
                decoration: BoxDecoration(
                  color: SgColors.darkSurfaceElevated,
                  shape: BoxShape.circle,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _FallbackAvatar extends StatelessWidget {
  const _FallbackAvatar({required this.label, required this.radius});

  final String label;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final normalized = label.trim();
    final initial = normalized.isEmpty ? 'S' : normalized.substring(0, 1).toUpperCase();

    return CircleAvatar(
      radius: radius,
      backgroundColor: SgColors.moonstone.withValues(alpha: 0.18),
      foregroundColor: SgColors.moonstone,
      child: Text(
        initial,
        style: TextStyle(
          fontSize: radius * 0.72,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}
