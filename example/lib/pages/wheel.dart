import 'package:flutter/material.dart';
import 'package:flutter_fortune_wheel/flutter_fortune_wheel.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';

import '../common/common.dart';
import '../widgets/widgets.dart';

class FortuneWheelPage extends HookWidget {
  static const kRouteName = 'FortuneWheelPage';

  static void go(BuildContext context) {
    context.goNamed(kRouteName);
  }

  @override
  Widget build(BuildContext context) {
    final slices = Constants.weightedFortuneValues;
    final alignment = useState(Alignment.topCenter);
    final selected = useStreamController<int>();
    final selectedIndex = useStream(selected.stream, initialData: 0).data ?? 0;
    final isAnimating = useState(false);

    final alignmentSelector = AlignmentSelector(
      selected: alignment.value,
      onChanged: (v) => alignment.value = v!,
    );

    void handleRoll() {
      selected.add(
        roll(slices.length),
      );
    }

    return AppLayout(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            alignmentSelector,
            const SizedBox(height: 8),
            RollButtonWithPreview(
              selected: selectedIndex,
              items: Constants.fortuneValues,
              onPressed: isAnimating.value ? null : handleRoll,
            ),
            const SizedBox(height: 8),
            Expanded(
              child: Column(
                children: [
                  Expanded(
                    child: FortuneWheel(
                      alignment: alignment.value,
                      selected: selected.stream,
                      onAnimationStart: () => isAnimating.value = true,
                      onAnimationEnd: () => isAnimating.value = false,
                      onFling: handleRoll,
                      hapticImpact: HapticImpact.heavy,
                      indicators: [
                        FortuneIndicator(
                          alignment: alignment.value,
                          child: TriangleIndicator(),
                        ),
                      ],
                      items: [
                        for (final slice in slices)
                          FortuneItem(
                            weight: slice.weight,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(slice.label),
                                Text(
                                  'Weight ${slice.weight.toStringAsFixed(1)}',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                            onTap: () => print(slice.label),
                          )
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(8, 16, 8, 8),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Larger weights create wider slices. Tap Roll or fling the wheel to verify the layout.',
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          alignment: WrapAlignment.center,
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            for (final slice in slices)
                              Chip(
                                label: Text(
                                  '${slice.label} (${slice.weight.toStringAsFixed(1)}x)',
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
