import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

class TwilioWidget extends StatefulWidget {
  final Map<String, dynamic> creationParams;

  const TwilioWidget(
    this.creationParams,
  ) : super();

  @override
  _TwilioWidgetState createState() => _TwilioWidgetState();
}

class _TwilioWidgetState extends State<TwilioWidget> {
  Widget _widget;

  @override
  Widget build(BuildContext context) {
    return _widget ??= AndroidView(
      viewType: 'twilio_unofficial_programmable_video/views',
      creationParams: widget.creationParams,
      creationParamsCodec: const StandardMessageCodec(),
      onPlatformViewCreated: (int viewId) {
        print('TwilioWidget created => $viewId, creationParams: ${widget.creationParams}');
      },
    );
  }
}
