import 'package:dartlin/dartlin.dart';
import 'package:twilio_programmable_video_platform_interface/twilio_programmable_video_platform_interface.dart';

NetworkQualityLevel networkQualityLevelFromInt(int level) =>
    when<int, NetworkQualityLevel>(level, {
      0: () => NetworkQualityLevel.NETWORK_QUALITY_LEVEL_ZERO,
      1: () => NetworkQualityLevel.NETWORK_QUALITY_LEVEL_ONE,
      2: () => NetworkQualityLevel.NETWORK_QUALITY_LEVEL_TWO,
      3: () => NetworkQualityLevel.NETWORK_QUALITY_LEVEL_THREE,
      4: () => NetworkQualityLevel.NETWORK_QUALITY_LEVEL_FOUR,
      5: () => NetworkQualityLevel.NETWORK_QUALITY_LEVEL_FIVE,
    }) ??
    NetworkQualityLevel.NETWORK_QUALITY_LEVEL_UNKNOWN;
