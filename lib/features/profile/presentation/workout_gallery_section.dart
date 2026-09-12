import 'package:flutter/material.dart';
import 'package:phosphor_icons/phosphor_icons.dart';

import '../../../core/theme/sg_colors.dart';
import '../../../core/theme/sg_spacing.dart';
import '../../feed/domain/feed_checkin.dart';

class WorkoutGallerySection extends StatelessWidget {
  const WorkoutGallerySection({required this.items, super.key});

  final List<FeedCheckin> items;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 1,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          const TabBar(
            tabs: <Widget>[
              Tab(
                icon: PhosphorIcon(PhosphorIconsRegular.gridFour),
                text: 'Treinos',
              ),
            ],
          ),
          const SizedBox(height: SgSpacing.sm),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: items.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 2,
              mainAxisSpacing: 2,
              childAspectRatio: 1,
            ),
            itemBuilder: (context, index) {
              final item = items[index];
              return Semantics(
                label:
                    '${item.workoutType.label}, ${item.durationMinutes} minutos',
                image: true,
                child: Image.network(
                  item.photoUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => const ColoredBox(
                    color: SgColors.darkSurfaceElevated,
                    child: Center(
                      child: PhosphorIcon(PhosphorIconsBold.imageBroken),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
