import 'dart:ui';

import 'package:flutter/material.dart';

class ParticipantBuffer {
  final bool audioEnabled;
  final String id;

  ParticipantBuffer({
    @required this.audioEnabled,
    @required this.id,
  })  : assert(audioEnabled != null),
        assert(id != null);
}

class ParticipantWidget extends StatelessWidget {
  final Widget child;
  final String id;
  final bool audioEnabled;
  final bool videoEnabled;
  final bool isRemote;
  final bool isDummy;
  final bool isDominant;

  const ParticipantWidget({
    Key key,
    @required this.child,
    @required this.audioEnabled,
    @required this.videoEnabled,
    @required this.id,
    @required this.isRemote,
    this.isDominant = false,
    this.isDummy = false,
  })  : assert(child != null),
        assert(audioEnabled != null),
        assert(videoEnabled != null),
        assert(isRemote != null),
        assert(isDominant != null),
        assert(isDummy != null),
        super(key: key);

  ParticipantWidget copyWith({
    Widget child,
    bool audioEnabled,
    bool videoEnabled,
    bool isDominant,
  }) {
    return ParticipantWidget(
      id: id,
      child: child ?? this.child,
      audioEnabled: audioEnabled ?? this.audioEnabled,
      videoEnabled: videoEnabled ?? this.videoEnabled,
      isDominant: isDominant ?? this.isDominant,
      isRemote: isRemote,
    );
  }

  @override
  Widget build(BuildContext context) {
    final children = <Widget>[];
    final icons = <Widget>[];
    if (!videoEnabled) {
      icons.add(_buildVideoEnabledIcon());
      children.add(
        ClipRect(
          // Need to clip this BackdropFilter, otherwise it will blur the entire screen
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              decoration: BoxDecoration(color: Colors.black.withOpacity(.1)),
              child: child,
            ),
          ),
        ),
      );
    } else {
      children.add(child);
    }
    children.add(Padding(
      padding: const EdgeInsets.all(8.0),
      child: AnimatedOpacity(
        duration: Duration(milliseconds: 500),
        opacity: isDominant ? 1 : 0,
        child: Icon(
          Icons.volume_up,
          color: Colors.white,
        ),
      ),
    ));
    if (!audioEnabled) {
      icons.add(_buildAudioEnabledIcon());
    }
    if (icons.isNotEmpty) {
      if (isRemote) {
        final rows = <Widget>[];
        rows.add(_buildRow(icons));
        if (!audioEnabled && !videoEnabled) {
          rows.add(_buildRow(_fitText('The camera and microphone are off', Colors.white24)));
        } else if (!audioEnabled) {
          rows.add(_buildRow(_fitText('The microphone is off', Colors.black26)));
        } else if (!videoEnabled) {
          rows.add(_buildRow(_fitText('The camera is off', Colors.white24)));
        }
        children.add(
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: rows,
          ),
        );
      } else {
        children.add(Column(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: icons,
        ));
      }
    }

    return Stack(
      children: children,
    );
  }

  List<Widget> _fitText(String text, Color color) {
    return [
      Flexible(
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Padding(
            padding: const EdgeInsets.only(left: 8.0, right: 8.0),
            child: Text(text, maxLines: 1, style: _buildTextStyle(color)),
          ),
        ),
      ),
    ];
  }

  TextStyle _buildTextStyle(Color color) {
    return TextStyle(
      color: color,
      shadows: <Shadow>[
        Shadow(
          blurRadius: 1.0,
          color: Color.fromARGB(255, 0, 0, 0),
        ),
        Shadow(
          blurRadius: 1.0,
          color: Color.fromARGB(24, 255, 255, 255),
        ),
      ],
      fontSize: 15,
    );
  }

  Widget _buildRow(List<Widget> children) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: children,
    );
  }

  Widget _buildAudioEnabledIcon() {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: CircleAvatar(
        maxRadius: 15,
        child: FittedBox(
          child: Icon(
            Icons.mic_off,
            color: Colors.black,
          ),
        ),
        backgroundColor: Colors.white24,
      ),
    );
  }

  Widget _buildVideoEnabledIcon() {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: CircleAvatar(
        maxRadius: 15,
        child: FittedBox(
          child: Icon(
            Icons.videocam_off,
            color: Colors.black,
          ),
        ),
        backgroundColor: Colors.white24,
      ),
    );
  }
}
