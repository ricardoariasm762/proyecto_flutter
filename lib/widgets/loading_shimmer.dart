import 'package:flutter/material.dart';

class LoadingShimmer extends StatefulWidget {
  const LoadingShimmer({super.key, this.itemCount = 4});

  final int itemCount;

  @override
  State<LoadingShimmer> createState() => _LoadingShimmerState();
}

class _LoadingShimmerState extends State<LoadingShimmer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final base = scheme.surfaceVariant;
    final highlight = Color.lerp(base, scheme.onSurface, 0.16) ?? scheme.surface;

    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) {
        final t = _ctrl.value;
        final begin = -1.0 + (2.0 * t);

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          itemCount: widget.itemCount,
          itemBuilder: (context, index) {
            return _ShimmerMask(
              baseColor: base,
              highlightColor: highlight,
              begin: begin,
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
      },
    );
  }
}

class _ShimmerMask extends StatelessWidget {
  const _ShimmerMask({
    required this.child,
    required this.baseColor,
    required this.highlightColor,
    required this.begin,
  });

  final Widget child;
  final Color baseColor;
  final Color highlightColor;
  final double begin;

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      blendMode: BlendMode.srcATop,
      shaderCallback: (bounds) {
        return LinearGradient(
          begin: Alignment(begin, 0),
          end: Alignment(begin + 1.0, 0),
          colors: [
            baseColor,
            highlightColor,
            baseColor,
          ],
          stops: const [0.2, 0.5, 0.8],
        ).createShader(bounds);
      },
      child: child,
    );
  }
}
