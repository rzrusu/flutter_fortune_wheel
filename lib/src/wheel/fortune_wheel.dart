part of 'wheel.dart';

enum HapticImpact { none, light, medium, heavy }

Offset _calculateWheelOffset(
    BoxConstraints constraints, TextDirection textDirection) {
  final smallerSide = getSmallerSide(constraints);
  var offsetX = constraints.maxWidth / 2;
  if (textDirection == TextDirection.rtl) {
    offsetX = offsetX * -1 + smallerSide / 2;
  }
  return Offset(offsetX, constraints.maxHeight / 2);
}

// kept for backwards reference in code history; not used anymore after weights

class _WeightedSlicesGeometry {
  final List<double> cumulativeCenters; // running center angles for each slice
  final List<double> sweepAngles; // sweep for each slice
  final List<double> cumulativeStarts; // start angle of each slice
  final double totalWeight;

  const _WeightedSlicesGeometry({
    required this.cumulativeCenters,
    required this.sweepAngles,
    required this.cumulativeStarts,
    required this.totalWeight,
  });
}

_WeightedSlicesGeometry _computeWeightedSlices(List<FortuneItem> items) {
  final weights = items.map((e) => e.weight).toList(growable: false);
  final totalWeight = weights.fold<double>(0.0, (a, b) => a + b);
  if (totalWeight == 0) {
    final uniformSweep = 2 * _math.pi / items.length;
    final starts = List<double>.generate(items.length, (i) => i * uniformSweep);
    final centers =
        List<double>.generate(items.length, (i) => starts[i] + uniformSweep / 2);
    return _WeightedSlicesGeometry(
      cumulativeCenters: centers,
      sweepAngles: List<double>.filled(items.length, uniformSweep),
      cumulativeStarts: starts,
      totalWeight: items.length.toDouble(),
    );
  }

  final sweeps = [
    for (final w in weights) (w / totalWeight) * (2 * _math.pi),
  ];
  // Ensure numerical stability: adjust last slice to close the circle exactly
  final sumSweeps = sweeps.fold<double>(0.0, (a, b) => a + b);
  final diff = 2 * _math.pi - sumSweeps;
  if (sweeps.isNotEmpty) {
    sweeps[sweeps.length - 1] = (sweeps.last + diff).clamp(0.0, 2 * _math.pi);
  }
  final starts = <double>[];
  double acc = 0.0;
  for (final s in sweeps) {
    starts.add(acc);
    acc += s;
  }
  final centers = [
    for (var i = 0; i < sweeps.length; i++) starts[i] + sweeps[i] / 2,
  ];
  return _WeightedSlicesGeometry(
    cumulativeCenters: centers,
    sweepAngles: sweeps,
    cumulativeStarts: starts,
    totalWeight: totalWeight,
  );
}

double _calculateAlignmentOffset(Alignment alignment) {
  if (alignment == Alignment.topRight) {
    return _math.pi * 0.25;
  }

  if (alignment == Alignment.centerRight) {
    return _math.pi * 0.5;
  }

  if (alignment == Alignment.bottomRight) {
    return _math.pi * 0.75;
  }

  if (alignment == Alignment.bottomCenter) {
    return _math.pi;
  }

  if (alignment == Alignment.bottomLeft) {
    return _math.pi * 1.25;
  }

  if (alignment == Alignment.centerLeft) {
    return _math.pi * 1.5;
  }

  if (alignment == Alignment.topLeft) {
    return _math.pi * 1.75;
  }

  return 0;
}

class _WheelData {
  final BoxConstraints constraints;
  final int itemCount;
  final TextDirection textDirection;

  late final double smallerSide = getSmallerSide(constraints);
  late final double largerSide = getLargerSide(constraints);
  late final double sideDifference = largerSide - smallerSide;
  late final Offset offset = _calculateWheelOffset(constraints, textDirection);
  late final Offset dOffset = Offset(
    (constraints.maxHeight - smallerSide) / 2,
    (constraints.maxWidth - smallerSide) / 2,
  );
  late final double diameter = smallerSide;
  late final double radius = diameter / 2;
  late final double itemAngle = 2 * _math.pi / itemCount;

  _WheelData({
    required this.constraints,
    required this.itemCount,
    required this.textDirection,
  });
}

/// A fortune wheel visualizes a (random) selection process as a spinning wheel
/// divided into uniformly sized slices, which correspond to the number of
/// [items].
///
/// ![](https://raw.githubusercontent.com/kevlatus/flutter_fortune_wheel/main/images/img-wheel-256.png?sanitize=true)
///
/// See also:
///  * [FortuneBar], which provides an alternative visualization
///  * [FortuneWidget()], which automatically chooses a fitting widget
///  * [Fortune.randomItem], which helps selecting random items from a list
///  * [Fortune.randomDuration], which helps choosing a random duration
class FortuneWheel extends HookWidget implements FortuneWidget {
  /// The default value for [indicators] on a [FortuneWheel].
  /// Currently uses a single [TriangleIndicator] on [Alignment.topCenter].
  static const List<FortuneIndicator> kDefaultIndicators = <FortuneIndicator>[
    FortuneIndicator(
      alignment: Alignment.topCenter,
      child: TriangleIndicator(),
    ),
  ];

  static const StyleStrategy kDefaultStyleStrategy = AlternatingStyleStrategy();

  /// {@macro flutter_fortune_wheel.FortuneWidget.items}
  final List<FortuneItem> items;

  /// {@macro flutter_fortune_wheel.FortuneWidget.selected}
  final Stream<int> selected;

  /// {@macro flutter_fortune_wheel.FortuneWidget.rotationCount}
  final int rotationCount;

  /// {@macro flutter_fortune_wheel.FortuneWidget.duration}
  final Duration duration;

  /// {@macro flutter_fortune_wheel.FortuneWidget.indicators}
  final List<FortuneIndicator> indicators;

  /// {@macro flutter_fortune_wheel.FortuneWidget.animationType}
  final Curve curve;

  /// {@macro flutter_fortune_wheel.FortuneWidget.onAnimationStart}
  final VoidCallback? onAnimationStart;

  /// {@macro flutter_fortune_wheel.FortuneWidget.onAnimationEnd}
  final VoidCallback? onAnimationEnd;

  /// {@macro flutter_fortune_wheel.FortuneWidget.styleStrategy}
  final StyleStrategy styleStrategy;

  /// {@macro flutter_fortune_wheel.FortuneWidget.animateFirst}
  final bool animateFirst;

  /// {@macro flutter_fortune_wheel.FortuneWidget.physics}
  final PanPhysics physics;

  /// {@macro flutter_fortune_wheel.FortuneWidget.onFling}
  final VoidCallback? onFling;

  /// The position to which the wheel aligns the selected value.
  ///
  /// Defaults to [Alignment.topCenter]
  final Alignment alignment;

  /// HapticFeedback strength on each section border crossing.
  ///
  /// Defaults to [HapticImpact.none]
  final HapticImpact hapticImpact;

  /// Called with the index of the item at the focused [alignment] whenever
  /// a section border is crossed.
  final ValueChanged<int>? onFocusItemChanged;

  double _getAngle(double progress) {
    return 2 * _math.pi * rotationCount * progress;
  }

  /// {@template flutter_fortune_wheel.FortuneWheel}
  /// Creates a new [FortuneWheel] with the given [items], which is centered
  /// on the [selected] value.
  ///
  /// {@macro flutter_fortune_wheel.FortuneWidget.ctorArgs}.
  ///
  /// See also:
  ///  * [FortuneBar], which provides an alternative visualization.
  /// {@endtemplate}
  FortuneWheel({
    Key? key,
    required this.items,
    this.rotationCount = FortuneWidget.kDefaultRotationCount,
    this.selected = const Stream<int>.empty(),
    this.duration = FortuneWidget.kDefaultDuration,
    this.curve = FortuneCurve.spin,
    this.indicators = kDefaultIndicators,
    this.styleStrategy = kDefaultStyleStrategy,
    this.animateFirst = true,
    this.onAnimationStart,
    this.onAnimationEnd,
    this.alignment = Alignment.topCenter,
    this.hapticImpact = HapticImpact.none,
    PanPhysics? physics,
    this.onFling,
    this.onFocusItemChanged,
  })  : physics = physics ?? CircularPanPhysics(),
        assert(items.length > 1),
        super(key: key);

  @override
  Widget build(BuildContext context) {
    // Arrow animation: Setting up the AnimationController and Animation
    final arrowController =
        useAnimationController(duration: const Duration(milliseconds: 300));
// Initializes an AnimationController with a duration of 300 milliseconds.
// This controller manages the timing of the animation.

    final arrowAnimation = Tween<double>(begin: 0, end: -20).animate(
      CurvedAnimation(
        parent: arrowController,
        curve: Curves.easeOut, // Curve for the forward animation (ease out)
        reverseCurve:
            Curves.easeIn, // Curve for the reverse animation (ease in)
      ),
    );
// Creates an Animation that interpolates from 0 to -20 using a Tween.
// The animation uses a CurvedAnimation to apply easing curves for smoother motion.

    useEffect(() {
      // Add a listener to the arrowController to monitor animation status changes
      arrowController.addStatusListener((status) {
        // If the animation has completed (reached the end)
        if (status == AnimationStatus.completed) {
          // Reverse the animation back to the starting point
          arrowController.reverse();
        }
      });
      // No cleanup necessary, so return null
      return null;
    }, [arrowController]); // The effect depends on arrowController

    void _animateArrow() {
      // Check if the animation has completed (reached the end)
      if (arrowController.isCompleted) {
        // Reset the animation controller to the beginning
        arrowController.reset();
      }
      // Start the animation moving forward from the current position
      arrowController.forward();
    }

    final rotateAnimCtrl = useAnimationController(duration: duration);
    final rotateAnim = CurvedAnimation(parent: rotateAnimCtrl, curve: curve);
    Future<void> animate() async {
      if (rotateAnimCtrl.isAnimating) {
        return;
      }

      await Future.microtask(() => onAnimationStart?.call());
      await rotateAnimCtrl.forward(from: 0);
      await Future.microtask(() => onAnimationEnd?.call());
    }

    useEffect(() {
      if (animateFirst) animate();
      return null;
    }, []);

    final selectedIndex = useState<int>(0);

    useEffect(() {
      final subscription = selected.listen((event) {
        selectedIndex.value = event;
        animate();
      });
      return subscription.cancel;
    }, []);

    final lastVibratedAngle = useRef<double>(0);

    return PanAwareBuilder(
      behavior: HitTestBehavior.translucent,
      physics: physics,
      onFling: onFling,
      builder: (context, panState) {
        return Stack(
          children: [
            AnimatedBuilder(
              animation: rotateAnim,
              builder: (context, _) {
                final size = MediaQuery.of(context).size;
                final meanSize = (size.width + size.height) / 2;
                final panFactor = 6 / meanSize;

                return LayoutBuilder(builder: (context, constraints) {
                  final wheelData = _WheelData(
                    constraints: constraints,
                    itemCount: items.length,
                    textDirection: Directionality.of(context),
                  );

                  final isAnimatingPanFactor =
                      rotateAnimCtrl.isAnimating ? 0 : 1;
                  // Compute weighted geometry
                  final geometry = _computeWeightedSlices(items);

                  // Determine the absolute angle of the selected item's center.
                  // Alignment offset is applied later during rendering.
                  final selectedAngle = -geometry.cumulativeCenters[
                      selectedIndex.value % items.length];
                  final panAngle =
                      panState.distance * panFactor * isAnimatingPanFactor;
                  final rotationAngle = _getAngle(rotateAnim.value);
                  final alignmentOffset = _calculateAlignmentOffset(alignment);
                  final totalAngle = selectedAngle + panAngle + rotationAngle;

                  final focusedIndex = _weightedBorderCross(
                    totalAngle,
                    lastVibratedAngle,
                    geometry,
                    hapticImpact,
                    _animateArrow,
                  );
                  if (focusedIndex != null) {
                    onFocusItemChanged?.call(focusedIndex % items.length);
                  }

                  final transformedItems = [
                    for (var i = 0; i < items.length; i++)
                      TransformedFortuneItem(
                        item: items[i],
                        angle: totalAngle +
                            alignmentOffset +
                            (geometry.cumulativeStarts[i] - _math.pi / 2),
                        offset: wheelData.offset,
                        sliceAngle: geometry.sweepAngles[i],
                      ),
                  ];

                  return SizedBox.expand(
                    child: _CircleSlices(
                      items: transformedItems,
                      wheelData: wheelData,
                      styleStrategy: styleStrategy,
                    ),
                  );
                });
              },
            ),
            for (var it in indicators)
              IgnorePointer(
                child: Container(
                  alignment: it.alignment,
                  child: AnimatedBuilder(
                    animation: arrowAnimation,
                    builder: (context, child) {
                      return Transform.translate(
                        offset: Offset(0, arrowAnimation.value),
                        child: child,
                      );
                    },
                    child: it.child,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  /// * vibrate and animate arrow when cross border
  // Replaced by weighted variant

  /// Weighted variant of border cross: determines when the spinning angle passes
  /// the boundary between two weighted slices and reports the newly focused index
  /// at the current [alignment]. Uses the precomputed [geometry].
  int? _weightedBorderCross(
    double angle,
    ObjectRef<double> lastVibratedAngle,
    _WeightedSlicesGeometry geometry,
    HapticImpact hapticImpact,
    VoidCallback animateArrow,
  ) {
    // Map current absolute angle to [0, 2*pi)
    double norm(double a) {
      final twoPi = 2 * _math.pi;
      a %= twoPi;
      if (a < 0) a += twoPi;
      return a;
    }

    final current = norm(-angle); // reverse sign: increasing angle spins CW
    final last = lastVibratedAngle.value.isFinite
        ? norm(-lastVibratedAngle.value)
        : current;

    // Find focused index by the center closest to current angle within its sweep
    int focused(double a) {
      final centers = geometry.cumulativeCenters;
      final sweeps = geometry.sweepAngles;
      for (var i = 0; i < centers.length; i++) {
        final start = geometry.cumulativeStarts[i];
        final end = start + sweeps[i];
        final s = norm(start);
        final e = norm(end);
        final inside = s <= e ? (a >= s && a < e) : (a >= s || a < e);
        if (inside) return i;
      }
      return 0;
    }

    final prevIndex = focused(last);
    final currIndex = focused(current);
    if (prevIndex == currIndex) return null;

    final hapticFeedbackFunction;
    switch (hapticImpact) {
      case HapticImpact.none:
        lastVibratedAngle.value = angle;
        return currIndex;
      case HapticImpact.heavy:
        hapticFeedbackFunction = HapticFeedback.heavyImpact;
        break;
      case HapticImpact.medium:
        hapticFeedbackFunction = HapticFeedback.mediumImpact;
        break;
      case HapticImpact.light:
        hapticFeedbackFunction = HapticFeedback.lightImpact;
        break;
    }
    hapticFeedbackFunction();
    animateArrow();
    lastVibratedAngle.value = angle;
    return currIndex;
  }
}
