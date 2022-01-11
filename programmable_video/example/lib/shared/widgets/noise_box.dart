import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';

enum NoiseBoxDensity {
  high,
  medium,
  low,
  xHigh,
  xLow,
}

class NoiseBox extends StatefulWidget {
  final NoiseBoxDensity density;
  final Color? backgroundColor;
  final Widget? child;

  const NoiseBox({
    Key? key,
    this.backgroundColor,
    this.child,
    this.density = NoiseBoxDensity.medium,
  }) : super(key: key);

  @override
  _NoiseBoxState createState() => _NoiseBoxState();
}

class _NoiseBoxState extends State<NoiseBox> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late int _density;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 60),
    );
    _animationController.repeat();
    switch (widget.density) {
      case NoiseBoxDensity.high:
        _density = 5;
        break;
      case NoiseBoxDensity.medium:
        _density = 7;
        break;
      case NoiseBoxDensity.low:
        _density = 10;
        break;
      case NoiseBoxDensity.xHigh:
        _density = 3;
        break;
      case NoiseBoxDensity.xLow:
        _density = 12;
        break;
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) => Container(
        color: widget.backgroundColor,
        width: constraints.biggest.width,
        height: constraints.biggest.height,
        child: AnimatedBuilder(
          animation: _animationController,
          builder: (BuildContext context, Widget? w) {
            final children = <Widget>[
              CustomPaint(
                painter: NoisePainter(
                  width: constraints.biggest.width,
                  height: constraints.biggest.height,
                  density: _density,
                ),
              ),
            ];
            final child = widget.child;
            if (child != null) {
              children.add(child);
            }
            return Stack(
              children: children
                  .map((e) =>
                      child ??
                      LimitedBox(
                        maxWidth: 0.0,
                        maxHeight: 0.0,
                        child: ConstrainedBox(constraints: const BoxConstraints.expand()),
                      ))
                  .toList(),
            );
          },
        ),
      ),
    );
  }
}

class NoisePainter extends CustomPainter {
  final double width;
  final double height;
  final int density;

  NoisePainter({
    required this.width,
    required this.height,
    required this.density,
  }) : assert(density >= 3 && density < math.min(width, height));

  List<Color> colors = <Color>[
    Colors.black,
    Colors.grey,
    Colors.blueGrey,
    Colors.red,
    Colors.green,
    Colors.blue,
    Colors.white,
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final random = math.Random();
    for (var w = 0; w < width; w += density) {
      for (var h = 0; h < height; h += density) {
        final offset = Offset(
          random.nextDouble() * width,
          random.nextDouble() * height,
        );
        final paint = Paint();
        paint.color = colors[random.nextInt(colors.length)];
        paint.strokeWidth = random.nextDouble() * 2;

        canvas.drawPoints(PointMode.points, <Offset>[offset], paint);
      }
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return true;
  }
}
