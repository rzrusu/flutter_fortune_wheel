part of 'wheel.dart';

enum HapticImpact { none, light, medium, heavy }

// Only mirror text when the wheel is slow enough to read.
const double _kTextMirrorMaxAngularVelocity = 4.0;

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

  // Initial proportional sweeps
  final sweeps = [
    for (final w in weights) (w / totalWeight) * (2 * _math.pi),
  ];
  // Ensure no slice collapses due to rounding; use a tiny epsilon.
  const double epsilon = 1e-8;
  for (var i = 0; i < sweeps.length; i++) {
    if (!(sweeps[i].isFinite) || sweeps[i] <= 0) {
      sweeps[i] = epsilon;
    }
  }
  // Renormalize to sum to 2*pi exactly.
  final sumSweeps = sweeps.fold<double>(0.0, (a, b) => a + b);
  final scale = (2 * _math.pi) / sumSweeps;
  for (var i = 0; i < sweeps.length; i++) {
    sweeps[i] *= scale;
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
  // Wheel slices start at 3 o'clock (0 rad) and sweep clockwise.
  if (alignment == Alignment.center) {
    return 0;
  }

  if (alignment == Alignment.centerRight) {
    return 0;
  }

  if (alignment == Alignment.bottomRight) {
    return _math.pi * 0.25;
  }

  if (alignment == Alignment.bottomCenter) {
    return _math.pi * 0.5;
  }

  if (alignment == Alignment.bottomLeft) {
    return _math.pi * 0.75;
  }

  if (alignment == Alignment.centerLeft) {
    return _math.pi;
  }

  if (alignment == Alignment.topLeft) {
    return _math.pi * 1.25;
  }

  if (alignment == Alignment.topCenter) {
    return _math.pi * 1.5;
  }

  if (alignment == Alignment.topRight) {
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

  /// Whether to mirror slice text on the opposite side of the spin direction.
  ///
  /// This keeps text readable on both sides of the wheel.
  /// Defaults to true.
  final bool mirrorTextOnOppositeSide;

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
    this.mirrorTextOnOppositeSide = true,
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

    // Precompute geometry once per build
    final geometry = _computeWeightedSlices(items);
    final lastRotationAngle = useRef<double?>(null);
    final lastRotationTimestamp = useRef<int?>(null);
    final lastAngularVelocity = useRef<double>(0.0);

    return PanAwareBuilder(
      behavior: HitTestBehavior.translucent,
      physics: physics,
      onFling: onFling,
      builder: (context, panState) {
        return Stack(
          children: [
            // Build wheel slices with base angles; rotate the whole layer per frame.
            LayoutBuilder(builder: (context, constraints) {
              final wheelData = _WheelData(
                constraints: constraints,
                itemCount: items.length,
                textDirection: Directionality.of(context),
              );

              // Build slices with base angles only.
              final baseItems = [
                for (var i = 0; i < items.length; i++)
                  TransformedFortuneItem(
                    item: items[i],
                    angle: geometry.cumulativeStarts[i],
                    offset: Offset.zero,
                    sliceAngle: geometry.sweepAngles[i],
                  ),
              ];

              return AnimatedBuilder(
                animation: rotateAnim,
                builder: (context, _) {
                  final size = MediaQuery.of(context).size;
                  final meanSize = (size.width + size.height) / 2;
                  final panFactor = 6 / meanSize;

                  final isAnimatingPanFactor = rotateAnimCtrl.isAnimating ? 0 : 1;

                  // Determine the absolute angle so that the selected item's CENTER
                  // aligns with the indicator.
                  final selectedAngle = -geometry.cumulativeCenters[
                      selectedIndex.value % items.length];
                  final panAngle =
                      panState.distance * panFactor * isAnimatingPanFactor;
                  final rotationAngle = _getAngle(rotateAnim.value);
                  final alignmentOffset = _calculateAlignmentOffset(alignment);
                  final totalAngle = selectedAngle + panAngle + rotationAngle;
                  final wheelRotation = totalAngle + alignmentOffset;
                  final now = DateTime.now().microsecondsSinceEpoch;
                  final lastTimestamp = lastRotationTimestamp.value;
                  final lastAngle = lastRotationAngle.value;
                  var angularVelocity = lastAngularVelocity.value;
                  if (lastTimestamp != null && lastAngle != null) {
                    final deltaTime = (now - lastTimestamp) /
                        Duration.microsecondsPerSecond;
                    if (deltaTime > 0) {
                      angularVelocity =
                          ((wheelRotation - lastAngle) / deltaTime).abs();
                    }
                  }
                  lastRotationTimestamp.value = now;
                  lastRotationAngle.value = wheelRotation;
                  lastAngularVelocity.value = angularVelocity;
                  final allowTextMirror = mirrorTextOnOppositeSide &&
                      angularVelocity <= _kTextMirrorMaxAngularVelocity;

                  final focusedIndex = _weightedBorderCross(
                    // Include alignment offset to detect focus at the actual indicator position
                    wheelRotation,
                    lastVibratedAngle,
                    geometry,
                    hapticImpact,
                    _animateArrow,
                  );
                  if (focusedIndex != null) {
                    onFocusItemChanged?.call(focusedIndex % items.length);
                  }

                  final wheel = RepaintBoundary(
                    child: SizedBox.expand(
                      child: _CircleSlices(
                        items: baseItems,
                        wheelData: wheelData,
                        styleStrategy: styleStrategy,
                        rotationAngle: wheelRotation,
                        mirrorTextOnOppositeSide: allowTextMirror,
                        animateTextRotation: allowTextMirror,
                      ),
                    ),
                  );

                  // Translate to wheel center, then rotate around that pivot
                  return Transform.translate(
                    offset: wheelData.offset,
                    child: Transform.rotate(
                      alignment: Alignment.topLeft,
                      angle: wheelRotation,
                      child: wheel,
                    ),
                  );
                },
              );
            }),
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

    // O(log n) lookup of segment index containing angle using cumulative starts
    int indexFor(double a) {
      final starts = geometry.cumulativeStarts;
      int lo = 0, hi = starts.length;
      while (lo < hi) {
        final mid = (lo + hi) >> 1;
        if (starts[mid] <= a) {
          lo = mid + 1;
        } else {
          hi = mid;
        }
      }
      final idx = lo - 1;
      return idx >= 0 ? idx : starts.length - 1;
    }

    final prevIndex = indexFor(last);
    final currIndex = indexFor(current);
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
