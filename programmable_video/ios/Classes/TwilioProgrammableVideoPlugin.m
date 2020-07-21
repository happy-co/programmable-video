#import "TwilioProgrammableVideoPlugin.h"
#if __has_include(<twilio_programmable_video/twilio_programmable_video-Swift.h>)
#import <twilio_programmable_video/twilio_programmable_video-Swift.h>
#else
// Support project import fallback if the generated compatibility header
// is not copied when this plugin is created as a library.
// https://forums.swift.org/t/swift-static-libraries-dont-copy-generated-objective-c-header/19816
#import "twilio_programmable_video-Swift.h"
#endif

@implementation TwilioProgrammableVideoPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  [SwiftTwilioProgrammableVideoPlugin registerWithRegistrar:registrar];
}
@end
