import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';

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
  double _bottom = 80;
  double _right = 10;
  double _width;
  double _height;
  final Duration _duration300ms = const Duration(milliseconds: 300);
  final Duration _duration0ms = const Duration(milliseconds: 0);
  Duration _duration;

  @override
  void initState() {
    super.initState();
    _duration = _duration300ms;
    widget.onButtonBarVisible.listen(_buttonBarVisible);
  }

  void _buttonBarVisible(bool visible) {
    if (!mounted) {
      return;
    }
    setState(() {
      _isButtonBarVisible = visible;
      if (visible) {
        if (_bottom <= 80) {
          _bottom = math.min(_bottom += 70, 80);
        }
      } else {
        if (_bottom <= 80) {
          _bottom = math.max(_bottom -= 70, 10);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    _width = widget.availableScreenSize.width * widget.scaleFactor;
    _height = _width * (widget.availableScreenSize.height / widget.availableScreenSize.width);

    Widget clippedVideo = Container(
      width: _width,
      height: _height,
      child: ClipRRect(
        child: widget.child,
        borderRadius: const BorderRadius.all(Radius.circular(20)),
      ),
    );

    return AnimatedPositioned(
      right: _right,
      bottom: _bottom,
      width: _width,
      height: _height,
      duration: _duration,
      child: Draggable(
        child: clippedVideo,
        feedback: clippedVideo,
        childWhenDragging: Container(),
        onDraggableCanceled: _onDraggableCanceled,
        onDragEnd: _onDragEnd,
        onDragStarted: _onDragStarted,
      ),
    );
  }

  void _onDragStarted() {
    // Don't want to animate the position changes whilst dragging
    _duration = _duration0ms;
  }

  void _onDragEnd(DraggableDetails details) {
    // Record the current positions as the starting point of the animation
    // to it's final corner in the [_onDraggableCanceled] function.
    setState(() {
      _bottom = (widget.availableScreenSize.height - (details.offset.dy + _height));
      _right = widget.availableScreenSize.width - (details.offset.dx + _width);
    });
  }

  void _onDraggableCanceled(Velocity velocity, Offset offset) {
    // Determine the center of the object being dragged so we can decide
    // in which corner the object should be placed.
    double dx = (_width / 2) + offset.dx;
    dx = dx < 0 ? 0 : dx >= widget.availableScreenSize.width ? widget.availableScreenSize.width - 1 : dx;
    double dy = (_height / 2) + offset.dy;
    dy = dy < 0 ? 0 : dy >= widget.availableScreenSize.height ? widget.availableScreenSize.height - 1 : dy;
    Offset draggableCenter = Offset(dx, dy);
    // We need a small delay here, because otherwise the property changes
    // in the [_onDragEnd] function will also animate, and we don't want that!
    Timer(const Duration(milliseconds: 50), () {
      setState(() {
        _duration = _duration300ms;
        if (Rect.fromLTRB(0, 0, widget.availableScreenSize.width / 2, widget.availableScreenSize.height / 2).contains(draggableCenter)) {
          _bottom = widget.availableScreenSize.height - (30 + _height);
          _right = widget.availableScreenSize.width - (10 + _width);
        } else if (Rect.fromLTRB(widget.availableScreenSize.width / 2, 0, widget.availableScreenSize.width, widget.availableScreenSize.height / 2).contains(draggableCenter)) {
          _bottom = widget.availableScreenSize.height - (30 + _height);
          _right = 10;
        } else if (Rect.fromLTRB(0, widget.availableScreenSize.height / 2, widget.availableScreenSize.width / 2, widget.availableScreenSize.height).contains(draggableCenter)) {
          _bottom = _isButtonBarVisible ? 70 : 10;
          _right = widget.availableScreenSize.width - (10 + _width);
        } else if (Rect.fromLTRB(widget.availableScreenSize.width / 2, widget.availableScreenSize.height / 2, widget.availableScreenSize.width, widget.availableScreenSize.height).contains(draggableCenter)) {
          _bottom = _isButtonBarVisible ? 70 : 10;
          _right = 10;
        }
      });
    });
  }
}
