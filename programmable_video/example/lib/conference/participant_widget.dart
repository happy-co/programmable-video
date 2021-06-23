import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:twilio_programmable_video/twilio_programmable_video.dart';
import 'package:twilio_programmable_video_example/conference/network_quality_indicator.dart';

class ParticipantBuffer {
  final bool audioEnabled;
  final String? id;

  ParticipantBuffer({
    required this.audioEnabled,
    required this.id,
  });
}

class ParticipantWidget extends StatelessWidget {
  final Widget child;
  final String? id;
  final bool audioEnabled;
  final bool videoEnabled;
  final bool isRemote;
  final bool isDummy;
  final bool isDominant;
  final bool audioEnabledLocally;
  final VoidCallback? toggleMute;
  final NetworkQualityLevel networkQualityLevel;
  final Stream<NetworkQualityLevelChangedEvent>? onNetworkQualityChanged;

  const ParticipantWidget({
    Key? key,
    required this.child,
    required this.audioEnabled,
    required this.videoEnabled,
    required this.id,
    required this.isRemote,
    this.networkQualityLevel = NetworkQualityLevel.NETWORK_QUALITY_LEVEL_UNKNOWN,
    this.onNetworkQualityChanged,
    this.toggleMute,
    this.audioEnabledLocally = true,
    this.isDominant = false,
    this.isDummy = false,
  }) : super(key: key);

  ParticipantWidget copyWith({
    Widget? child,
    bool? audioEnabled,
    bool? videoEnabled,
    bool? isDominant,
    bool? audioEnabledLocally,
  }) {
    return ParticipantWidget(
      id: id,
      audioEnabled: audioEnabled ?? this.audioEnabled,
      videoEnabled: videoEnabled ?? this.videoEnabled,
      isDominant: isDominant ?? this.isDominant,
      audioEnabledLocally: audioEnabledLocally ?? this.audioEnabledLocally,
      isRemote: isRemote,
      toggleMute: toggleMute,
      networkQualityLevel: networkQualityLevel,
      onNetworkQualityChanged: onNetworkQualityChanged,
      child: child ?? this.child,
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
    } else if (!audioEnabledLocally) {
      icons.add(_buildMutedIcon());
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
        } else if (!audioEnabledLocally) {
          rows.add(_buildRow(_fitText('You muted them', Colors.black26)));
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

    children.add(NetworkQualityIndicator(
      networkQualityIndicatorPosition: NetworkQualityIndicatorPosition.bottomCenter,
      bottom: 10,
      networkQualityLevel: networkQualityLevel,
      showFromNetworkQualityLevelAndBelow: NetworkQualityLevel.NETWORK_QUALITY_LEVEL_THREE,
      onNetworkQualityChanged: onNetworkQualityChanged,
    ));

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onLongPress: isRemote && toggleMute != null ? toggleMute : null,
      child: Stack(
        children: children,
      ),
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
        backgroundColor: Colors.white24,
        child: FittedBox(
          child: Icon(
            Icons.mic_off,
            color: Colors.black,
            key: Key('microphone-off-icon'),
          ),
        ),
      ),
    );
  }

  Widget _buildMutedIcon() {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: CircleAvatar(
        maxRadius: 15,
        backgroundColor: Colors.white24,
        child: FittedBox(
          child: Icon(
            Icons.volume_off,
            color: Colors.black,
            key: Key('microphone-off-icon'),
          ),
        ),
      ),
    );
  }

  Widget _buildVideoEnabledIcon() {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: CircleAvatar(
        maxRadius: 15,
        backgroundColor: Colors.white24,
        child: FittedBox(
          child: Icon(
            Icons.videocam_off,
            color: Colors.black,
            key: Key('videocam-off-icon'),
          ),
        ),
      ),
    );
  }
}
