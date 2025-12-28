part of 'wheel.dart';

double _normalizeAngle(double angle) {
  final twoPi = 2 * _math.pi;
  angle %= twoPi;
  if (angle < 0) angle += twoPi;
  return angle;
}

bool _isAngleOnLeftSide(double angle) {
  final normalized = _normalizeAngle(angle);
  return normalized > _math.pi / 2 && normalized < _math.pi * 1.5;
}

class _TransformedCircleSlice extends StatelessWidget {
  final TransformedFortuneItem item;
  final StyleStrategy styleStrategy;
  final _WheelData wheelData;
  final int index;
  final double rotationAngle;
  final bool mirrorTextOnOppositeSide;
  final bool animateTextRotation;

  const _TransformedCircleSlice({
    Key? key,
    required this.item,
    required this.styleStrategy,
    required this.index,
    required this.wheelData,
    required this.rotationAngle,
    required this.mirrorTextOnOppositeSide,
    required this.animateTextRotation,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = item.style ??
        styleStrategy.getItemStyle(theme, index, wheelData.itemCount);
    final sliceAngle =
        item.sliceAngle == 0.0 ? wheelData.itemAngle : item.sliceAngle;
    var textRotation = 0.0;
    if (mirrorTextOnOppositeSide) {
      final centerAngle = item.angle + sliceAngle / 2;
      final absoluteAngle = centerAngle + rotationAngle;
      if (_isAngleOnLeftSide(absoluteAngle)) {
        textRotation = _math.pi;
      }
    }

    return _CircleSliceLayout(
      handler: item,
      textRotation: textRotation,
      animateTextRotation: animateTextRotation,
      child: DefaultTextStyle(
        textAlign: style.textAlign,
        style: style.textStyle,
        child: item.child,
      ),
      slice: _CircleSlice(
        radius: wheelData.radius,
        angle: sliceAngle,
        fillColor: style.color,
        strokeColor: style.borderColor,
        strokeWidth: style.borderWidth,
      ),
    );
  }
}

class _CircleSlices extends StatelessWidget {
  final List<TransformedFortuneItem> items;
  final StyleStrategy styleStrategy;
  final _WheelData wheelData;
  final double rotationAngle;
  final bool mirrorTextOnOppositeSide;
  final bool animateTextRotation;

  const _CircleSlices({
    Key? key,
    required this.items,
    required this.styleStrategy,
    required this.wheelData,
    required this.rotationAngle,
    required this.mirrorTextOnOppositeSide,
    required this.animateTextRotation,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final slices = [
      for (var i = 0; i < items.length; i++)
        Transform.translate(
          offset: items[i].offset,
          child: Transform.rotate(
            alignment: Alignment.topLeft,
            angle: items[i].angle,
            child: _TransformedCircleSlice(
              item: items[i],
              styleStrategy: styleStrategy,
              index: i,
              wheelData: wheelData,
              rotationAngle: rotationAngle,
              mirrorTextOnOppositeSide: mirrorTextOnOppositeSide,
              animateTextRotation: animateTextRotation,
            ),
          ),
        ),
    ];

    return Stack(
      children: slices,
    );
  }
}
