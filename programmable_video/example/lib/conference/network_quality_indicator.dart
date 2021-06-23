import 'dart:async';

import 'package:flutter/material.dart';
import 'package:twilio_programmable_video/twilio_programmable_video.dart';

enum NetworkQualityIndicatorPosition {
  topLeft,
  topCenter,
  topRight,
  middleLeft,
  middleCenter,
  middleRight,
  bottomLeft,
  bottomCenter,
  bottomRight,
}

class _NetworkQualityIndicatorRect {
  final double? left;
  final double? top;
  final double? right;
  final double? bottom;

  _NetworkQualityIndicatorRect(this.left, this.top, this.right, this.bottom);
}

class NetworkQualityIndicator extends StatefulWidget {
  final double width;
  final double height;
  final double? top;
  final double? left;
  final double? right;
  final double? bottom;
  final NetworkQualityLevel networkQualityLevel;
  final NetworkQualityLevel showFromNetworkQualityLevelAndBelow;
  final Stream<NetworkQualityLevelChangedEvent>? onNetworkQualityChanged;
  final NetworkQualityIndicatorPosition? networkQualityIndicatorPosition;

  const NetworkQualityIndicator({
    Key? key,
    this.width = 50,
    this.height = 15,
    this.top,
    this.left,
    this.right,
    this.bottom,
    this.networkQualityLevel = NetworkQualityLevel.NETWORK_QUALITY_LEVEL_UNKNOWN,
    this.showFromNetworkQualityLevelAndBelow = NetworkQualityLevel.NETWORK_QUALITY_LEVEL_THREE,
    this.onNetworkQualityChanged,
    this.networkQualityIndicatorPosition,
  }) : super(key: key);

  @override
  _NetworkQualityIndicatorState createState() => _NetworkQualityIndicatorState();
}

class _NetworkQualityIndicatorState extends State<NetworkQualityIndicator> {
  StreamSubscription<NetworkQualityLevelChangedEvent>? _onNetworkQualityChanged;

  final List<List<Color>> _barColors = [
    [Colors.white, Colors.white, Colors.white, Colors.white, Colors.white],
    [Colors.red, Colors.white, Colors.white, Colors.white, Colors.white],
    [Colors.orange, Colors.orangeAccent, Colors.white, Colors.white, Colors.white],
    [Colors.orangeAccent, Colors.green.shade200, Colors.green.shade300, Colors.white, Colors.white],
    [Colors.green.shade200, Colors.green.shade300, Colors.green.shade400, Colors.green, Colors.white],
    [Colors.green.shade300, Colors.green.shade400, Colors.green, Colors.green.shade600, Colors.green.shade700],
  ];

  final timeout = const Duration(seconds: 5);
  final ms = const Duration(milliseconds: 1);
  final periodicDuration = const Duration(milliseconds: 100);

  Timer? _timer;
  var _opacity = 0.0;
  var _index = 0;
  late double _barWidth;
  final _duration = const Duration(milliseconds: 500);

  @override
  void initState() {
    super.initState();
    if (widget.onNetworkQualityChanged != null) {
      _onNetworkQualityChanged = widget.onNetworkQualityChanged!.listen((event) {
        _setQuality(event.networkQualityLevel);
      });
    }
    _setQuality(widget.networkQualityLevel);
  }

  @override
  void dispose() {
    _cancelTimer();
    _stopListening();
    super.dispose();
  }

  Future<void> _stopListening() async {
    await _onNetworkQualityChanged?.cancel();
  }

  void _setQuality(NetworkQualityLevel networkQualityLevel) {
    setState(() {
      _index = networkQualityLevel.index - 1;
      if (_index < 0) {
        return;
      }
      if (_index < widget.showFromNetworkQualityLevelAndBelow.index) {
        _opacity = 1;
        _cancelTimer();
      } else {
        if (_opacity == 1) {
          _timer ??= startTimeout();
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    _barWidth = widget.width / 7;
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        return _buildNetworkQualityIndicator(constraints.biggest);
      },
    );
  }

  Widget _buildNetworkQualityIndicator(Size size) {
    var rect = _getRect(size);

    return Stack(
      children: <Widget>[
        Positioned(
          left: rect.left,
          top: rect.top,
          right: rect.right,
          bottom: rect.bottom,
          child: AnimatedOpacity(
            duration: _duration,
            opacity: _opacity,
            child: Container(
              width: widget.width,
              height: widget.height,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  buildBar(1, 1.8),
                  buildBar(2, 2.1),
                  buildBar(3, 2.7),
                  buildBar(4, 3.8),
                  buildBar(5, 5.0),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget buildBar(int barIndex, double heightFactor) {
    if (_index < 0) {
      return Container();
    }
    return AnimatedContainer(
      duration: _duration,
      width: _barWidth,
      height: (widget.height / 5) * heightFactor,
      decoration: BoxDecoration(
        color: _barColors[_index][barIndex - 1],
        border: Border.all(color: Colors.black38),
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(_barWidth / 4),
          topLeft: Radius.circular(_barWidth / 4),
        ),
      ),
    );
  }

  Timer startTimeout([int? milliseconds]) {
    final duration = milliseconds == null ? timeout : ms * milliseconds;
    return Timer(duration, () {
      setState(() {
        _opacity = 0;
      });
    });
  }

  void _cancelTimer() {
    final timer = _timer;
    if (timer == null) {
      return;
    }
    timer.cancel();
    _timer = null;
  }

  _NetworkQualityIndicatorRect _getRect(Size size) {
    double? top;
    double? left;
    double? right;
    double? bottom;
    if (widget.networkQualityIndicatorPosition != null) {
      // ignore: missing_enum_constant_in_switch
      switch (widget.networkQualityIndicatorPosition) {
        case NetworkQualityIndicatorPosition.topLeft:
          top = 0.0 + (widget.top ?? 0.0);
          left = 0.0 + (widget.left ?? 0.0);
          break;
        case NetworkQualityIndicatorPosition.topCenter:
          top = 0.0 + (widget.top ?? 0.0);
          left = ((size.width - widget.width) / 2) + (widget.left ?? 0.0);
          break;
        case NetworkQualityIndicatorPosition.topRight:
          top = 0.0 + (widget.top ?? 0.0);
          right = 0.0 + (widget.right ?? 0.0);
          break;
        case NetworkQualityIndicatorPosition.middleLeft:
          top = ((size.height - widget.height) / 2) + (widget.top ?? 0.0);
          left = 0.0 + (widget.left ?? 0.0);
          break;
        case NetworkQualityIndicatorPosition.middleCenter:
          top = ((size.height - widget.height) / 2) + (widget.top ?? 0.0);
          left = ((size.width - widget.width) / 2) + (widget.left ?? 0.0);
          break;
        case NetworkQualityIndicatorPosition.middleRight:
          top = ((size.height - widget.height) / 2) + (widget.top ?? 0.0);
          right = 0.0 + (widget.right ?? 0.0);
          break;
        case NetworkQualityIndicatorPosition.bottomLeft:
          bottom = 0.0 + (widget.bottom ?? 0.0);
          left = 0.0 + (widget.left ?? 0.0);
          break;
        case NetworkQualityIndicatorPosition.bottomCenter:
          bottom = 0.0 + (widget.bottom ?? 0.0);
          left = ((size.width - widget.width) / 2) + (widget.left ?? 0.0);
          break;
        case NetworkQualityIndicatorPosition.bottomRight:
          bottom = 0.0 + (widget.bottom ?? 0.0);
          right = 0.0 + (widget.right ?? 0.0);
          break;
      }
    } else {
      top = widget.top;
      left = widget.left;
      right = widget.right;
      bottom = widget.bottom;
    }
    return _NetworkQualityIndicatorRect(left, top, right, bottom);
  }
}
