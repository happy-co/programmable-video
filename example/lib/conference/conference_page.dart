import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:twilio_unofficial_programmable_video/twilio_unofficial_programmable_video.dart';
import 'package:twilio_unofficial_programmable_video_example/conference/conference_button_bar.dart';
import 'package:twilio_unofficial_programmable_video_example/conference/draggable_publisher.dart';
import 'package:twilio_unofficial_programmable_video_example/conference/participant_model.dart';
import 'package:twilio_unofficial_programmable_video_example/room/room_model.dart';
import 'package:twilio_unofficial_programmable_video_example/shared/services/platform_service.dart';
import 'package:twilio_unofficial_programmable_video_example/shared/widgets/noise_box.dart';
import 'package:twilio_unofficial_programmable_video_example/shared/widgets/platform_alert_dialog.dart';
import 'package:twilio_unofficial_programmable_video_example/shared/widgets/platform_exception_alert_dialog.dart';
import 'package:wakelock/wakelock.dart';

class ConferencePage extends StatefulWidget {
  final RoomModel roomModel;

  const ConferencePage({
    Key key,
    @required this.roomModel,
  }) : super(key: key);

  @override
  _ConferencePageState createState() => _ConferencePageState();
}

class _ConferencePageState extends State<ConferencePage> {
  bool _videoEnabled = true;
  bool _microphoneEnabled = true;
  CameraCapturer _cameraCapturer;

  Room _room;
  String _deviceId;
  final StreamController<bool> _onButtonBarVisible = StreamController<bool>.broadcast();

  final List<ParticipantModel> _participants = [];

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations(<DeviceOrientation>[
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    _wakeLock(true);
    _getDeviceId();
    _connectToRoom();
  }

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations(<DeviceOrientation>[
      DeviceOrientation.landscapeRight,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    _wakeLock(false);
    _onButtonBarVisible.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false,
      child: GestureDetector(
        onTap: null,
        child: Scaffold(
          backgroundColor: Colors.black,
          body: LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              return Stack(
                children: <Widget>[
                  _buildParticipants(context, constraints.biggest),
                  ConferenceButtonBar(
                    videoEnabled: _videoEnabled,
                    microphoneEnabled: _microphoneEnabled,
                    onVideoEnabled: _onVideoEnabled,
                    onMicrophoneEnabled: _onMicrophoneEnabled,
                    onHangup: _onHangup,
                    onSwitchCamera: _onSwitchCamera,
                    onPersonAdd: _onPersonAdd,
                    onPersonRemove: _onPersonRemove,
                    onShow: _onShowBar,
                    onHide: _onHideBar,
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Future<void> _getDeviceId() async {
    try {
      _deviceId = await PlatformService.deviceId;
    } catch (err) {
      print(err);
      _deviceId = DateTime.now().millisecondsSinceEpoch.toString();
    }
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> _connectToRoom() async {
    try {
      await TwilioUnofficialProgrammableVideo.setSpeakerphoneOn(true);
      _cameraCapturer = CameraCapturer(CameraSource.FRONT_CAMERA);
      var connectOptions = ConnectOptions(widget.roomModel.token)
        ..roomName(widget.roomModel.name)
        ..preferAudioCodecs([OpusCodec()])
        ..audioTracks([LocalAudioTrack(_microphoneEnabled)])
        ..videoTracks([LocalVideoTrack(true, _cameraCapturer)]);

      _room = await TwilioUnofficialProgrammableVideo.connect(connectOptions);

      _room.onConnected.listen(_onConnected);
      _room.onParticipantConnected.listen(_onParticipantConnected);
      _room.onParticipantDisconnected.listen(_onParticipantDisconnected);
      _room.onConnectFailure.listen(_onConnectFailure);
    } on PlatformException catch (err) {
      await PlatformExceptionAlertDialog(
        title: 'An error occurred',
        exception: err,
      ).show(context);
      Navigator.of(context).pop();
    } catch (err) {
      print(err);
    }
  }

  ParticipantModel _buildParticipant({Widget child, bool isRemote = true, String id}) {
    return ParticipantModel(
      id: id,
      isRemote: isRemote,
      widget: Stack(
        children: <Widget>[child],
      ),
    );
  }

  void _onConnected(RoomEvent roomEvent) {
    setState(() {
      _participants.add(_buildParticipant(child: roomEvent.room.localParticipant.localVideoTracks[0].localVideoTrack.widget(), isRemote: false, id: _deviceId));
      for (final remoteParticipant in roomEvent.room.remoteParticipants) {
        print('Adding participant already present in the room ${remoteParticipant.sid}');
        _addRemoteParticipantListeners(remoteParticipant);
        for (final remoteVideoTrackPublication in remoteParticipant.remoteVideoTracks) {
          if (remoteVideoTrackPublication.isTrackSubscribed) {
            _participants.insert(
              0,
              _buildParticipant(
                child: remoteVideoTrackPublication.remoteVideoTrack.widget(),
                id: remoteParticipant.sid,
              ),
            );
          }
        }
      }
    });
  }

  void _onParticipantConnected(RoomEvent roomEvent) {
    _addRemoteParticipantListeners(roomEvent.remoteParticipant);
  }

  void _addRemoteParticipantListeners(RemoteParticipant remoteParticipant) {
    print('Adding videoTrack listeners to remoteParticipant ${remoteParticipant.sid}');
    remoteParticipant.onVideoTrackSubscribed.listen(_onVideoTrackSubscribed);
    remoteParticipant.onVideoTrackUnsubscribed.listen(_onVideoTrackUnSubscribed);
  }

  void _onParticipantDisconnected(RoomEvent roomEvent) {
    print('onParticipantDisconnected: ${roomEvent.remoteParticipant.sid}');
    setState(() {
      _participants.removeWhere((ParticipantModel p) => p.id == roomEvent.remoteParticipant.sid);
    });
  }

  Future<void> _onConnectFailure(RoomEvent roomEvent) async {
    print('ConnectFailure: ${roomEvent.exception}');
    await PlatformAlertDialog(
      title: 'Connect failure',
      content: roomEvent.exception.message,
      defaultActionText: 'OK',
    ).show(context);
    Navigator.of(context).pop();
  }

  void _onVideoTrackSubscribed(RemoteParticipantEvent remoteParticipantEvent) {
    setState(() {
      _participants.insert(
        0,
        _buildParticipant(
          child: remoteParticipantEvent.remoteVideoTrack.widget(),
          id: remoteParticipantEvent.remoteParticipant.sid,
        ),
      );
    });
  }

  void _onVideoTrackUnSubscribed(RemoteParticipantEvent remoteParticipantEvent) {
    print('VideoTrackUnsubscribed, ${remoteParticipantEvent.remoteParticipant.sid}, ${remoteParticipantEvent.remoteVideoTrack.sid}');
  }

  void _onVideoEnabled() {
    final localVideoTrack = _room.localParticipant.localVideoTracks[0].localVideoTrack;
    localVideoTrack.enable(!localVideoTrack.isEnabled);
    setState(() {
      _videoEnabled = !_videoEnabled;
    });
    print('onVideoEnabled: $_videoEnabled');
  }

  void _onMicrophoneEnabled() {
    final localAudioTrack = _room.localParticipant.localAudioTracks[0].localAudioTrack;
    localAudioTrack.enable(!localAudioTrack.isEnabled);
    setState(() {
      _microphoneEnabled = !_microphoneEnabled;
    });
    print('onMicrophoneEnabled: $_microphoneEnabled');
  }

  Future<void> _onHangup() async {
    print('onHangup');
    await _room.disconnect();
    Navigator.of(context).pop();
  }

  void _onSwitchCamera() {
    print('onSwitchCamera');
    _cameraCapturer.switchCamera();
  }

  void _onPersonAdd() {
    setState(() {
      if (_participants.length < 18) {
        _participants.insert(
          0,
          ParticipantModel(
            id: (_participants.length + 1).toString(),
            widget: Stack(
              children: <Widget>[
                const Placeholder(),
                Center(
                  child: Text(
                    (_participants.length + 1).toString(),
                    style: const TextStyle(
                      shadows: <Shadow>[
                        Shadow(
                          blurRadius: 3.0,
                          color: Color.fromARGB(255, 0, 0, 0),
                        ),
                        Shadow(
                          blurRadius: 8.0,
                          color: Color.fromARGB(255, 255, 255, 255),
                        ),
                      ],
                      fontSize: 80,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      } else {
        PlatformAlertDialog(
          title: 'Maximum reached',
          content: 'Currently the lay-out can only render a maximum of 18 participants',
          defaultActionText: 'OK',
        ).show(context);
      }
    });
  }

  void _onPersonRemove() {
    print('onPersonRemove');
    if (_participants.length > 1) {
      setState(() {
        _participants.removeAt(0);
      });
    }
  }

  Widget _buildParticipants(BuildContext context, Size size) {
    final children = <Widget>[];

    if (_participants.length <= 2) {
      _buildOverlayLayout(context, size, children);
      return Stack(children: children);
    }

    void buildInCols(bool removeLocalBeforeChunking, bool moveLastOfEachRowToNextRow, int columns) {
      _buildLayoutInGrid(
        context,
        size,
        children,
        removeLocalBeforeChunking: removeLocalBeforeChunking,
        moveLastOfEachRowToNextRow: moveLastOfEachRowToNextRow,
        columns: columns,
      );
    }

    if (_participants.length <= 3) {
      buildInCols(true, false, 1);
    } else if (_participants.length == 5) {
      buildInCols(false, true, 2);
    } else if (_participants.length <= 6 || _participants.length == 8) {
      buildInCols(false, false, 2);
    } else if (_participants.length == 7 || _participants.length == 9) {
      buildInCols(true, false, 2);
    } else if (_participants.length == 10) {
      buildInCols(false, true, 3);
    } else if (_participants.length == 13 || _participants.length == 16) {
      buildInCols(true, false, 3);
    } else if (_participants.length <= 18) {
      buildInCols(false, false, 3);
    }

    return Column(
      children: children,
    );
  }

  void _buildOverlayLayout(BuildContext context, Size size, List<Widget> children) {
    if (_participants.isEmpty) {
      children.add(Container(
        child: const Center(
          child: CircularProgressIndicator(),
        ),
      ));
      return;
    }
    if (_participants.length == 1) {
      children.add(_buildNoiseBox());
    } else {
      final remoteParticipant = _participants.firstWhere((ParticipantModel participant) => participant.isRemote, orElse: () => null);
      if (remoteParticipant != null) {
        children.add(remoteParticipant.widget);
      }
    }

    final localParticipant = _participants.firstWhere((ParticipantModel participant) => !participant.isRemote, orElse: () => null);
    if (localParticipant != null) {
      children.add(DraggablePublisher(
        child: localParticipant.widget,
        availableScreenSize: size,
        onButtonBarVisible: _onButtonBarVisible.stream,
      ));
    }
  }

  void _buildLayoutInGrid(BuildContext context, Size size, List<Widget> children, {bool removeLocalBeforeChunking = false, bool moveLastOfEachRowToNextRow = false, int columns = 2}) {
    ParticipantModel localParticipant;
    if (removeLocalBeforeChunking) {
      localParticipant = _participants.firstWhere((ParticipantModel participant) => !participant.isRemote, orElse: () => null);
      if (localParticipant != null) {
        _participants.remove(localParticipant);
      }
    }
    final chunkedParticipants = chunk(array: _participants, size: columns);
    if (localParticipant != null) {
      chunkedParticipants.last.add(localParticipant);
      _participants.add(localParticipant);
    }

    if (moveLastOfEachRowToNextRow) {
      for (var i = 0; i < chunkedParticipants.length - 1; i++) {
        var participant = chunkedParticipants[i].removeLast();
        chunkedParticipants[i + 1].insert(0, participant);
      }
    }

    for (final participantChunk in chunkedParticipants) {
      final rowChildren = <Widget>[];
      for (final participant in participantChunk) {
        rowChildren.add(
          Container(
            width: size.width / participantChunk.length,
            child: participant.widget,
          ),
        );
      }
      children.add(
        Container(
          height: size.height / chunkedParticipants.length,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: rowChildren,
          ),
        ),
      );
    }
  }

  NoiseBox _buildNoiseBox() {
    return NoiseBox(
      density: NoiseBoxDensity.xLow,
      backgroundColor: Colors.grey.shade900,
      child: Center(
        child: Container(
          color: Colors.black54,
          width: double.infinity,
          height: 40,
          child: Center(
            child: Text(
              'Waiting for another participant to connect to the room...',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white),
            ),
          ),
        ),
      ),
    );
  }

  List<List<T>> chunk<T>({@required List<T> array, @required int size}) {
    final result = <List<T>>[];
    if (array.isEmpty || size <= 0) {
      return result;
    }
    var first = 0;
    var last = size;
    final totalLoop = array.length % size == 0 ? array.length ~/ size : array.length ~/ size + 1;
    for (var i = 0; i < totalLoop; i++) {
      if (last > array.length) {
        result.add(array.sublist(first, array.length));
      } else {
        result.add(array.sublist(first, last));
      }
      first = last;
      last = last + size;
    }
    return result;
  }

  void _onShowBar() {
    setState(() {
      SystemChrome.setEnabledSystemUIOverlays([SystemUiOverlay.bottom, SystemUiOverlay.top]);
    });
    _onButtonBarVisible.add(true);
  }

  void _onHideBar() {
    setState(() {
      SystemChrome.setEnabledSystemUIOverlays([SystemUiOverlay.bottom]);
    });
    _onButtonBarVisible.add(false);
  }

  Future<void> _wakeLock(bool enable) async {
    try {
      return await (enable ? Wakelock.enable() : Wakelock.disable());
    } catch (err) {
      print('Unable to change the Wakelock and set it to $enable');
      print(err);
    }
  }
}
