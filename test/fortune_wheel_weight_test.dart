import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_fortune_wheel/flutter_fortune_wheel.dart';

import 'test_helpers.dart';

void main() {
  group('FortuneWheel weighted slices', () {
    testWidgets('label rotation reflects weighted slice angle (half sweep)',
        (tester) async {
      // Two items with 3:1 weights should yield half-sweep rotations of
      // 3*pi/4 and pi/4 respectively for their label Transforms.
      await pumpFortuneWidget(
        tester,
        FortuneWheel(
          animateFirst: false,
          rotationCount: 0,
          selected: const Stream<int>.empty(),
          items: const [
            FortuneItem(child: Text('A'), weight: 3),
            FortuneItem(child: Text('B'), weight: 1),
          ],
        ),
      );

      await tester.pumpAndSettle();

      Transform rotatedTransformOf(Text text) {
        final textFinder = find.text(text.data!);
        final ancestorFinder =
            find.ancestor(of: textFinder, matching: find.byType(Transform));
        final transforms = ancestorFinder.evaluate().map((e) => e.widget as Transform);
        expect(transforms, isNotEmpty);
        // Find the first transform that applies a meaningful rotation.
        for (final t in transforms) {
          final m = t.transform.storage;
          final angle = math.atan2(m[1], m[0]);
          if (angle.abs() > 0.01) {
            return t;
          }
        }
        // Fallback to the closest ancestor if none exceeded threshold.
        return transforms.first;
      }

      double rotationAngleOf(Transform t) {
        final m = t.transform.storage;
        return math.atan2(m[1], m[0]).abs();
      }

      final tA = rotatedTransformOf(const Text('A'));
      final tB = rotatedTransformOf(const Text('B'));

      final angleA = rotationAngleOf(tA);
      final angleB = rotationAngleOf(tB);

      // angleA should be > angleB for weights 3:1
      expect(angleA, greaterThan(angleB));
      // Half-sweeps should sum to pi for two items
      expect(angleA + angleB, moreOrLessEquals(math.pi, epsilon: 0.05));
    });
  });
}


