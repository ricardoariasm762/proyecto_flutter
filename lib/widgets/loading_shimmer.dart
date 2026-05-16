import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

/// Placeholder animado (estilo [Taxi-App](https://github.com/OpenConsultingGroup/Taxi-App)) adaptado al tema actual.
class LoadingShimmer extends StatelessWidget {
  const LoadingShimmer({super.key, this.itemCount = 4});

  final int itemCount;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final base = scheme.surfaceContainerHighest;
    final highlight = Color.lerp(base, scheme.onSurface, 0.12) ?? scheme.surfaceContainerHigh;

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: itemCount,
      itemBuilder: (context, index) {
        return Shimmer.fromColors(
          baseColor: base,
          highlightColor: highlight,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: base,
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        height: 16,
                        margin: const EdgeInsets.only(right: 24),
                        decoration: BoxDecoration(
                          color: base,
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        height: 12,
                        margin: const EdgeInsets.only(right: 48),
                        decoration: BoxDecoration(
                          color: base,
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        height: 12,
                        margin: const EdgeInsets.only(right: 80),
                        decoration: BoxDecoration(
                          color: base,
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
