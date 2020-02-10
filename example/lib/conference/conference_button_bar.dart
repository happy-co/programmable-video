import 'dart:async';

import 'package:flutter/material.dart';
import 'package:twilio_unofficial_programmable_video_example/conference/participant_widget.dart';
import 'package:twilio_unofficial_programmable_video_example/shared/widgets/circle_button.dart';

class ConferenceButtonBar extends StatefulWidget {
  final VoidCallback onVideoEnabled;
  final VoidCallback onAudioEnabled;
  final VoidCallback onHangup;
  final VoidCallback onSwitchCamera;
  final VoidCallback onPersonAdd;
  final VoidCallback onPersonRemove;
  final VoidCallback onHide;
  final VoidCallback onShow;
  final Stream<ParticipantMediaEnabled> videoEnabled;
  final Stream<ParticipantMediaEnabled> audioEnabled;

  const ConferenceButtonBar({
    Key key,
    this.onVideoEnabled,
    this.onAudioEnabled,
    this.onHangup,
    this.onSwitchCamera,
    this.onPersonAdd,
    this.onPersonRemove,
    @required this.videoEnabled,
    @required this.audioEnabled,
    this.onHide,
    this.onShow,
  })  : assert(videoEnabled != null),
        assert(audioEnabled != null),
        super(key: key);

  @override
  _ConferenceButtonBarState createState() => _ConferenceButtonBarState();
}

class _ConferenceButtonBarState extends State<ConferenceButtonBar> {
  var _bottom = 0.0;
  Timer _timer;
  int _remaining;
  var _videoEnabled = true;
  var _audioEnabled = true;
  final double _hidden = -100;
  final double _visible = 0;

  final Duration timeout = const Duration(seconds: 5);
  final Duration ms = const Duration(milliseconds: 1);
  final Duration periodicDuration = const Duration(milliseconds: 100);

  Timer startTimeout([int milliseconds]) {
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
    if (_timer == null) {
      return;
    }
    _timer.cancel();
    _timer = null;
  }

  void _resumeTimer() {
    // resume the timer only when there is no timer active or when
    // the bar is not already hidden.
    if ((_timer != null && _timer.isActive) || _bottom == _hidden) {
      return;
    }
    _timer = startTimeout(_remaining);
  }

  void _toggleBar() {
    setState(() {
      _bottom = _bottom == _visible ? _hidden : _visible;
      if (_bottom == _visible && widget.onShow != null) {
        widget.onShow();
      }
      if (_bottom == _hidden && widget.onHide != null) {
        widget.onHide();
      }
    });
  }

  void _toggleBarOnEnd() {
    if (_timer != null) {
      if (_timer.isActive) {
        _timer.cancel();
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
  }

  @override
  void dispose() {
    super.dispose();
    if (_timer != null && _timer.isActive) {
      _timer.cancel();
      _timer = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      bottom: 0,
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTapDown: (_) => _pauseTimer(),
        onTapUp: (_) => _toggleBar(),
        onTapCancel: () => _resumeTimer(),
        child: Stack(
          children: <Widget>[
            AnimatedPositioned(
              bottom: _bottom,
              left: 0,
              right: 0,
              duration: const Duration(milliseconds: 300),
              curve: Curves.linear,
              child: _buildRow(context),
              onEnd: _toggleBarOnEnd,
            ),
          ],
        ),
      ),
    );
  }

  void _onPressed(VoidCallback callback) {
    if (callback != null) {
      callback();
    }
    if (_timer != null && _timer.isActive) {
      _timer.cancel();
    }
    _timer = startTimeout();
  }

  Widget _buildRow(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          CircleButton(
            radius: 25,
            child: StreamBuilder<ParticipantMediaEnabled>(
                stream: widget.videoEnabled,
                initialData: ParticipantMediaEnabled(id: null, isEnabled: _videoEnabled),
                builder: (context, snapshot) {
                  if (snapshot.data.id == null) {
                    _videoEnabled = snapshot.data.isEnabled;
                  }
                  return Icon(
                    _videoEnabled ? Icons.videocam : Icons.videocam_off,
                    color: Colors.white,
                  );
                }),
            onPressed: () => _onPressed(widget.onVideoEnabled),
          ),
          CircleButton(
            radius: 25,
            child: StreamBuilder<ParticipantMediaEnabled>(
                stream: widget.audioEnabled,
                initialData: ParticipantMediaEnabled(id: null, isEnabled: _audioEnabled),
                builder: (context, snapshot) {
                  if (snapshot.data.id == null) {
                    _audioEnabled = snapshot.data.isEnabled;
                  }
                  return Icon(
                    _audioEnabled ? Icons.mic : Icons.mic_off,
                    color: Colors.white,
                  );
                }),
            onPressed: () => _onPressed(widget.onAudioEnabled),
          ),
          CircleButton(
            radius: 35,
            child: const RotationTransition(
              turns: AlwaysStoppedAnimation<double>(135 / 360),
              child: Icon(
                Icons.phone,
                color: Colors.white,
                size: 40,
              ),
            ),
            color: Colors.red.withAlpha(200),
            onPressed: () => _onPressed(widget.onHangup),
          ),
          CircleButton(
            radius: 25,
            child: const Icon(Icons.switch_camera, color: Colors.white),
            onPressed: () => _onPressed(widget.onSwitchCamera),
          ),
          CircleButton(
            radius: 25,
            child: const Icon(Icons.person_add, color: Colors.white),
            onPressed: () => _onPressed(widget.onPersonAdd),
            onLongPress: () => _onPressed(widget.onPersonRemove),
          ),
        ],
      ),
    );
  }
}
