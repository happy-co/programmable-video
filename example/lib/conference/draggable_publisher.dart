import 'dart:async';

import 'package:flutter/material.dart';
import 'package:twilio_unofficial_programmable_video_example/conference/clipped_video.dart';

class DraggablePublisher extends StatefulWidget {
  final Size availableScreenSize;
  final Widget child;
  final double scaleFactor;
  final Stream<bool> onButtonBarVisible;

  const DraggablePublisher({
    Key key,
    @required this.availableScreenSize,
    this.child,
    @required this.onButtonBarVisible,

    /// The portion of the screen the DraggableWidget should use.
    this.scaleFactor = .25,
  })  : assert(scaleFactor != null && scaleFactor > 0 && scaleFactor <= .4),
        assert(availableScreenSize != null),
        assert(onButtonBarVisible != null),
        super(key: key);

  @override
  _DraggablePublisherState createState() => _DraggablePublisherState();
}

class _DraggablePublisherState extends State<DraggablePublisher> {
  bool _isButtonBarVisible = true;
  double _width;
  double _height;
  double _top;
  double _left;
  final Duration _duration300ms = const Duration(milliseconds: 300);
  final Duration _duration0ms = const Duration(milliseconds: 0);
  Duration _duration;
  StreamSubscription _streamSubscription;

  @override
  void initState() {
    super.initState();
    _duration = _duration300ms;
    _width = widget.availableScreenSize.width * widget.scaleFactor;
    _height = _width * (widget.availableScreenSize.height / widget.availableScreenSize.width);
    _top = widget.availableScreenSize.height - 80 - _height;
    _left = widget.availableScreenSize.width - 10 - _width;

    _streamSubscription = widget.onButtonBarVisible.listen(_buttonBarVisible);
  }

  @override
  void dispose() {
    _streamSubscription.cancel();
    super.dispose();
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
        onPointerUp: (_) {
          _duration = _duration300ms;
          _positionWidget();
        },
        child: ClippedVideo(
          height: _height,
          width: _width,
          child: widget.child,
        ),
      ),
    );
  }

  void _positionWidget() {
    // Determine the center of the object being dragged so we can decide
    // in which corner the object should be placed.
    var dx = (_width / 2) + _left;
    dx = dx < 0 ? 0 : dx >= widget.availableScreenSize.width ? widget.availableScreenSize.width - 1 : dx;
    var dy = (_height / 2) + _top;
    dy = dy < 0 ? 0 : dy >= widget.availableScreenSize.height ? widget.availableScreenSize.height - 1 : dy;
    final draggableCenter = Offset(dx, dy);
    // We need a small delay here, because otherwise the property changes
    // in the [_onDragEnd] function will also animate, and we don't want that!

    setState(() {
      _duration = _duration300ms;
      if (Rect.fromLTRB(0, 0, widget.availableScreenSize.width / 2, widget.availableScreenSize.height / 2).contains(draggableCenter)) {
        // Top-left
        _top = (_isButtonBarVisible ? 30 : 10);
        _left = 10;
      } else if (Rect.fromLTRB(widget.availableScreenSize.width / 2, 0, widget.availableScreenSize.width, widget.availableScreenSize.height / 2).contains(draggableCenter)) {
        // Top-right
        _top = (_isButtonBarVisible ? 30 : 10);
        _left = widget.availableScreenSize.width - 10 - _width;
      } else if (Rect.fromLTRB(0, widget.availableScreenSize.height / 2, widget.availableScreenSize.width / 2, widget.availableScreenSize.height).contains(draggableCenter)) {
        // Bottom-left
        _top = widget.availableScreenSize.height - (_isButtonBarVisible ? 80 : 10) - _height;
        _left = 10;
      } else if (Rect.fromLTRB(widget.availableScreenSize.width / 2, widget.availableScreenSize.height / 2, widget.availableScreenSize.width, widget.availableScreenSize.height).contains(draggableCenter)) {
        // Bottom-right
        _top = widget.availableScreenSize.height - (_isButtonBarVisible ? 80 : 10) - _height;
        _left = widget.availableScreenSize.width - 10 - _width;
      }
    });
  }
}
