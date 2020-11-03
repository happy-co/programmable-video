import Flutter
import TwilioVideo

public class Mapper {
    public static func networkQualityLevelToString(_ networkQualityLevel: NetworkQualityLevel) -> String {
        var networkQualityLevelString: String

        switch networkQualityLevel {
            case NetworkQualityLevel.unknown:
                networkQualityLevelString = "NETWORK_QUALITY_LEVEL_UNKNOWN"
            case NetworkQualityLevel.zero:
                networkQualityLevelString = "NETWORK_QUALITY_LEVEL_ZERO"
            case NetworkQualityLevel.one:
                networkQualityLevelString = "NETWORK_QUALITY_LEVEL_ONE"
            case NetworkQualityLevel.two:
                networkQualityLevelString = "NETWORK_QUALITY_LEVEL_TWO"
            case NetworkQualityLevel.three:
                networkQualityLevelString = "NETWORK_QUALITY_LEVEL_THREE"
            case NetworkQualityLevel.four:
                networkQualityLevelString = "NETWORK_QUALITY_LEVEL_FOUR"
            case NetworkQualityLevel.five:
                networkQualityLevelString = "NETWORK_QUALITY_LEVEL_FIVE"
            default:
                networkQualityLevelString = "NETWORK_QUALITY_LEVEL_UNKNOWN"
        }

       return networkQualityLevelString
    }
}
