#import "TwilioUnofficialProgrammableVideoPlugin.h"
#if __has_include(<twilio_unofficial_programmable_video/twilio_unofficial_programmable_video-Swift.h>)
#import <twilio_unofficial_programmable_video/twilio_unofficial_programmable_video-Swift.h>
#else
// Support project import fallback if the generated compatibility header
// is not copied when this plugin is created as a library.
// https://forums.swift.org/t/swift-static-libraries-dont-copy-generated-objective-c-header/19816
#import "twilio_unofficial_programmable_video-Swift.h"
#endif

@implementation TwilioUnofficialProgrammableVideoPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  [SwiftTwilioUnofficialProgrammableVideoPlugin registerWithRegistrar:registrar];
}
@end
