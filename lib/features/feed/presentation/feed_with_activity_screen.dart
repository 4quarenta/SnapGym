import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_icons/phosphor_icons.dart';

import '../../../core/theme/sg_colors.dart';
import '../../../core/theme/sg_spacing.dart';
import '../../activity/data/activity_repository.dart';
import 'feed_screen.dart';

class FeedWithActivityScreen extends ConsumerWidget {
  const FeedWithActivityScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unread = ref
        .watch(unreadActivityCountProvider)
        .when(
          data: (value) => value,
          loading: () => 0,
          error: (error, stack) => 0,
        );

    return Stack(
      children: <Widget>[
        const FeedScreen(),
        Positioned(
          top: MediaQuery.paddingOf(context).top + SgSpacing.sm,
          right: SgSpacing.md,
          child: Material(
            color: Theme.of(
              context,
            ).colorScheme.surface.withValues(alpha: 0.92),
            shape: const CircleBorder(),
            elevation: 1,
            child: IconButton(
              tooltip: unread == 0
                  ? 'Atividade'
                  : 'Atividade: $unread ${unread == 1 ? 'novidade' : 'novidades'}',
              onPressed: () => context.push('/activity'),
              icon: Badge(
                isLabelVisible: unread > 0,
                backgroundColor: SgColors.orange,
                textColor: SgColors.jet,
                label: Text(unread > 99 ? '99+' : '$unread'),
                child: PhosphorIcon(
                  unread > 0
                      ? PhosphorIconsFill.bell
                      : PhosphorIconsRegular.bell,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
