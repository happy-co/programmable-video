import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:twilio_programmable_video_example/conference/clipped_video.dart';

class DraggablePublisher extends StatefulWidget {
  final Size availableScreenSize;
  final Widget child;
  final double scaleFactor;
  final Stream<bool> onButtonBarVisible;
  final Stream<double> onButtonBarHeight;

  const DraggablePublisher({
    Key? key,
    required this.availableScreenSize,
    required this.child,
    required this.onButtonBarVisible,
    required this.onButtonBarHeight,

    /// The portion of the screen the DraggableWidget should use.
    this.scaleFactor = .25,
  }) : super(key: key);

  @override
  _DraggablePublisherState createState() => _DraggablePublisherState();
}

class _DraggablePublisherState extends State<DraggablePublisher> {
  bool _isButtonBarVisible = true;
  double _buttonBarHeight = 0;
  late double _width;
  late double _height;
  late double _top;
  late double _left;
  late double _viewPaddingTop;
  late double _viewPaddingBottom;
  final double _padding = 8.0;
  final Duration _duration300ms = const Duration(milliseconds: 300);
  final Duration _duration0ms = const Duration(milliseconds: 0);
  late Duration _duration;
  late StreamSubscription _streamSubscription;
  late StreamSubscription _streamHeightSubscription;

  @override
  void initState() {
    super.initState();
    _duration = _duration300ms;
    _width = widget.availableScreenSize.width * widget.scaleFactor;
    _height = _width * (widget.availableScreenSize.height / widget.availableScreenSize.width);
    _top = widget.availableScreenSize.height - (_buttonBarHeight + _padding) - _height;
    _left = widget.availableScreenSize.width - _padding - _width;

    _streamSubscription = widget.onButtonBarVisible.listen(_buttonBarVisible);
    _streamHeightSubscription = widget.onButtonBarHeight.listen(_getButtonBarHeight);
  }

  @override
  void didChangeDependencies() {
    final mediaQuery = MediaQuery.of(context);
    _viewPaddingTop = mediaQuery.viewPadding.top;
    _viewPaddingBottom = mediaQuery.viewPadding.bottom;
    super.didChangeDependencies();
  }

  @override
  void dispose() {
    _streamSubscription.cancel();
    _streamHeightSubscription.cancel();
    super.dispose();
  }

  void _getButtonBarHeight(double height) {
    setState(() {
      _buttonBarHeight = height;
      _positionWidget();
    });
  }

  void _buttonBarVisible(bool visible) {
    if (!mounted) {
      return;
    }
    setState(() {
      _isButtonBarVisible = visible;
      if (_duration == _duration300ms) {
        // only position the widget when we are not currently dragging it around
        _positionWidget();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedPositioned(
      top: _top,
      left: _left,
      width: _width,
      height: _height,
      duration: _duration,
      child: Listener(
        onPointerDown: (_) => _duration = _duration0ms,
        onPointerMove: (PointerMoveEvent event) {
          setState(() {
            _left = (_left + event.delta.dx).roundToDouble();
            _top = (_top + event.delta.dy).roundToDouble();
          });
        },
        onPointerUp: (_) => _positionWidget(),
        onPointerCancel: (_) => _positionWidget(),
        child: ClippedVideo(
          height: _height,
          width: _width,
          child: widget.child,
        ),
      ),
    );
  }

  double _getCurrentStatusBarHeight() {
    if (_isButtonBarVisible) {
      return _viewPaddingTop;
    }
    final _defaultViewPaddingTop = kIsWeb
        ? 0.0
        : Platform.isIOS
            ? 20.0
            : 24;
    if (_viewPaddingTop > _defaultViewPaddingTop) {
      // There must be a hardware notch in the display.
      return _viewPaddingTop;
    }
    return 0.0;
  }

  double _getCurrentButtonBarHeight() {
    if (_isButtonBarVisible) {
      return _buttonBarHeight + _viewPaddingBottom;
    }
    return _viewPaddingBottom;
  }

  void _positionWidget() {
    // Determine the center of the object being dragged so we can decide
    // in which corner the object should be placed.
    var dx = (_width / 2) + _left;
    dx = dx < 0
        ? 0
        : dx >= widget.availableScreenSize.width
            ? widget.availableScreenSize.width - 1
            : dx;
    var dy = (_height / 2) + _top;
    dy = dy < 0
        ? 0
        : dy >= widget.availableScreenSize.height
            ? widget.availableScreenSize.height - 1
            : dy;
    final draggableCenter = Offset(dx, dy);

    setState(() {
      _duration = _duration300ms;
      if (Rect.fromLTRB(0, 0, widget.availableScreenSize.width / 2, widget.availableScreenSize.height / 2).contains(draggableCenter)) {
        // Top-left
        _top = _getCurrentStatusBarHeight() + _padding;
        _left = _padding;
      } else if (Rect.fromLTRB(widget.availableScreenSize.width / 2, 0, widget.availableScreenSize.width, widget.availableScreenSize.height / 2).contains(draggableCenter)) {
        // Top-right
        _top = _getCurrentStatusBarHeight() + _padding;
        _left = widget.availableScreenSize.width - _padding - _width;
      } else if (Rect.fromLTRB(0, widget.availableScreenSize.height / 2, widget.availableScreenSize.width / 2, widget.availableScreenSize.height).contains(draggableCenter)) {
        // Bottom-left
        _top = widget.availableScreenSize.height - (_getCurrentButtonBarHeight() + _padding) - _height;
        _left = _padding;
      } else if (Rect.fromLTRB(widget.availableScreenSize.width / 2, widget.availableScreenSize.height / 2, widget.availableScreenSize.width, widget.availableScreenSize.height).contains(draggableCenter)) {
        // Bottom-right
        _top = widget.availableScreenSize.height - (_getCurrentButtonBarHeight() + _padding) - _height;
        _left = widget.availableScreenSize.width - _padding - _width;
      }
    });
  }
}
