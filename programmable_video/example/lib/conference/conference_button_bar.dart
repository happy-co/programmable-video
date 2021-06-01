import 'dart:async';

import 'package:after_layout/after_layout.dart';
import 'package:flutter/material.dart';
import 'package:twilio_programmable_video_example/shared/widgets/circle_button.dart';

class ConferenceButtonBar extends StatefulWidget {
  final VoidCallback onVideoEnabled;
  final VoidCallback onAudioEnabled;
  final VoidCallback onHangup;
  final VoidCallback onSwitchCamera;
  final VoidCallback onPersonAdd;
  final VoidCallback onPersonRemove;
  final VoidCallback toggleFlashlight;
  final void Function(double) onHeight;
  final VoidCallback onHide;
  final VoidCallback onShow;
  final Stream<bool> videoEnabled;
  final Stream<bool> audioEnabled;
  final Stream<Map<String, bool>> flashState;

  const ConferenceButtonBar({
    Key? key,
    required this.onVideoEnabled,
    required this.onAudioEnabled,
    required this.onHangup,
    required this.onSwitchCamera,
    required this.onPersonAdd,
    required this.onPersonRemove,
    required this.toggleFlashlight,
    required this.videoEnabled,
    required this.audioEnabled,
    required this.flashState,
    required this.onHeight,
    required this.onHide,
    required this.onShow,
  }) : super(key: key);

  @override
  _ConferenceButtonBarState createState() => _ConferenceButtonBarState();
}

class _ConferenceButtonBarState extends State<ConferenceButtonBar> with AfterLayoutMixin<ConferenceButtonBar> {
  double? _bottom = -100.0;
  var _timer;
  late int _remaining;
  var _videoEnabled = true;
  var _audioEnabled = true;
  late double _hidden;
  late double _visible;
  final _keyButtonBarHeight = GlobalKey();
  bool hasFlash = false;
  bool flashEnabled = false;

  final Duration timeout = const Duration(seconds: 5);
  final Duration ms = const Duration(milliseconds: 1);
  final Duration periodicDuration = const Duration(milliseconds: 100);
  final List<StreamSubscription> _subscriptions = [];

  Timer startTimeout([int? milliseconds]) {
    final duration = milliseconds == null ? timeout : ms * milliseconds;
    _remaining = duration.inMilliseconds;
    return Timer.periodic(periodicDuration, (Timer timer) {
      _remaining -= periodicDuration.inMilliseconds;
      if (_remaining <= 0) {
        timer.cancel();
        _toggleBar();
      }
    });
  }

  void _pauseTimer() {
    final timer = _timer;
    if (timer == null) {
      return;
    }
    timer.cancel();
    _timer = null;
  }

  void _resumeTimer() {
    // resume the timer only when there is no timer active or when
    // the bar is not already hidden.
    final timer = _timer;
    if ((timer != null && timer.isActive) || _bottom == _hidden) {
      return;
    }
    _timer = startTimeout(_remaining);
  }

  void _toggleBar() {
    setState(() {
      _bottom = _bottom == _visible ? _hidden : _visible;
      if (_bottom == _visible) {
        widget.onShow();
      }
      if (_bottom == _hidden) {
        widget.onHide();
      }
    });
  }

  void _toggleBarOnEnd() {
    final timer = _timer;
    if (timer != null) {
      if (timer.isActive) {
        timer.cancel();
      }
      _timer = null;
    }
    if (_bottom == 0) {
      _timer = startTimeout();
    }
  }

  @override
  void initState() {
    super.initState();
    _timer = startTimeout();
    _subscriptions.add(widget.flashState.listen((event) => setState(() {
          final hasFlash = event['hasFlash'];
          if (hasFlash != null) {
            this.hasFlash = hasFlash;
          }
          final flashEnabled = event['flashEnabled'];
          if (flashEnabled != null) {
            this.flashEnabled = flashEnabled;
          }
        })));
  }

  @override
  void didChangeDependencies() {
    _visible = MediaQuery.of(context).viewPadding.bottom;
    super.didChangeDependencies();
  }

  @override
  void afterFirstLayout(BuildContext context) {
    final renderBoxButtonBar = _keyButtonBarHeight.currentContext!.findRenderObject() as RenderBox;
    final heightButtonBar = renderBoxButtonBar.size.height;
    // Because the `didChangeDependencies` fires before the `afterFirstLayout`, we can use the `_visible` property here.
    _hidden = -(heightButtonBar + _visible);
    widget.onHeight(heightButtonBar);
    _toggleBar();
  }

  @override
  void dispose() {
    super.dispose();
    final timer = _timer;
    if (timer != null && timer.isActive) {
      timer.cancel();
      _timer = null;
    }
    _subscriptions.forEach((subscription) => subscription.cancel());
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      bottom: 0,
      child: GestureDetector(
        key: Key('show-hide-button-bar-gesture'),
        behavior: HitTestBehavior.translucent,
        onTapDown: (_) => _pauseTimer(),
        onTapUp: (_) => _toggleBar(),
        onTapCancel: () => _resumeTimer(),
        child: Stack(
          children: <Widget>[
            AnimatedPositioned(
              key: Key('button-bar'),
              bottom: _bottom,
              left: 0,
              right: 0,
              duration: const Duration(milliseconds: 300),
              curve: Curves.linear,
              onEnd: _toggleBarOnEnd,
              child: _buildRow(context),
            ),
          ],
        ),
      ),
    );
  }

  void _onPressed(VoidCallback? callback) {
    if (callback != null) {
      callback();
    }
    final timer = _timer;
    if (timer != null && timer.isActive) {
      timer.cancel();
    }
    _timer = startTimeout();
  }

  Widget _buildRow(BuildContext context) {
    return Padding(
      key: _keyButtonBarHeight,
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: <Widget>[
          CircleButton(
            key: Key('camera-button'),
            onPressed: () => _onPressed(widget.onVideoEnabled),
            child: StreamBuilder<bool>(
                stream: widget.videoEnabled,
                initialData: _videoEnabled,
                builder: (context, snapshot) {
                  _videoEnabled = snapshot.data ?? false;

                  return Icon(
                    _videoEnabled ? Icons.videocam : Icons.videocam_off,
                    color: Colors.white,
                  );
                }),
          ),
          CircleButton(
            key: Key('microphone-button'),
            onPressed: () => _onPressed(widget.onAudioEnabled),
            child: StreamBuilder<bool>(
                stream: widget.audioEnabled,
                initialData: _audioEnabled,
                builder: (context, snapshot) {
                  final audioEnabled = snapshot.data;
                  if (audioEnabled != null) {
                    _audioEnabled = audioEnabled;
                  }

                  return Icon(
                    _audioEnabled ? Icons.mic : Icons.mic_off,
                    color: Colors.white,
                  );
                }),
          ),
          CircleButton(
            radius: 35,
            color: Colors.red.withAlpha(200),
            key: Key('hangup-button'),
            onPressed: () => _onPressed(widget.onHangup),
            child: const RotationTransition(
              turns: AlwaysStoppedAnimation<double>(135 / 360),
              child: Icon(
                Icons.phone,
                color: Colors.white,
                size: 40,
              ),
            ),
          ),
          CircleButton(
            key: Key('switch-camera-button'),
            onPressed: () => _onPressed(widget.onSwitchCamera),
            child: const Icon(Icons.switch_camera, color: Colors.white),
          ),
          CircleButton(
            key: Key('add-person-button'),
            onPressed: () => _onPressed(widget.onPersonAdd),
            onLongPress: () => _onPressed(widget.onPersonRemove),
            child: const Icon(Icons.person_add, color: Colors.white),
          ),
          if (hasFlash)
            CircleButton(
              key: Key('toggle-flashlight-button'),
              onPressed: () => _onPressed(widget.toggleFlashlight),
              child: Icon(flashEnabled ? Icons.highlight_off : Icons.highlight, color: Colors.white),
            )
        ],
      ),
    );
  }
}
