import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

class ButtonToProgress extends StatefulWidget {
  final double height;
  final double progressHeight;
  final String? loadingText;
  final Duration duration;
  final TextStyle? loadingTextStyle;
  final VoidCallback? onPressed;
  final Stream<bool>? onLoading;
  final Widget child;

  const ButtonToProgress({
    Key? key,
    this.height = 40.0,
    this.progressHeight = 5.0,
    this.loadingText,
    this.duration = const Duration(milliseconds: 300),
    this.loadingTextStyle,
    this.onPressed,
    this.onLoading,
    required this.child,
  })  : assert(progressHeight > 0 && progressHeight <= height),
        super(key: key);

  @override
  _ButtonToProgressState createState() => _ButtonToProgressState();
}

class _ButtonToProgressState extends State<ButtonToProgress> {
  late double _height;
  double _opacity = 0;
  bool _isLoading = false;

  StreamSubscription<bool>? _subscription;

  @override
  void initState() {
    super.initState();
    _height = widget.height;
    if (widget.onLoading != null) {
      _subscription = widget.onLoading!.listen((bool isLoading) {
        setState(() {
          _isLoading = isLoading;
          _height = isLoading ? widget.progressHeight : widget.height;
          _opacity = isLoading ? 1 : 0;
        });
      });
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: widget.height,
      child: Stack(
        children: [
          if (widget.loadingText == null)
            Container()
          else
            Padding(
              padding: EdgeInsets.only(bottom: widget.progressHeight),
              child: AnimatedOpacity(
                opacity: _opacity,
                duration: Duration(milliseconds: widget.duration.inMilliseconds + 200),
                curve: Curves.easeInCubic,
                child: Center(
                  child: FittedBox(
                    child: Text(
                      widget.loadingText!,
                      style: widget.loadingTextStyle,
                    ),
                  ),
                ),
              ),
            ),
          AnimatedPadding(
            duration: widget.duration,
            padding: EdgeInsets.only(
              top: math.max(widget.height - _height, 0),
            ),
            child: AnimatedContainer(
              duration: widget.duration,
              height: _height,
              width: double.infinity,
              child: _isLoading ? const LinearProgressIndicator() : widget.child,
            ),
          ),
        ],
      ),
    );
  }
}
