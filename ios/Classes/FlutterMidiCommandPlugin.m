#import "FlutterMidiCommandPlugin.h"
#if __has_include(<midi_controller/midi_controller-Swift.h>)
#import <midi_controller/midi_controller-Swift.h>
#else
// Support project import fallback if the generated compatibility header
// is not copied when this plugin is created as a library.
// https://forums.swift.org/t/swift-static-libraries-dont-copy-generated-objective-c-header/19816
#import "midi_controller-Swift.h"
#endif



@implementation FlutterMidiCommandPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  [SwiftFlutterMidiCommandPlugin registerWithRegistrar:registrar];
}
@end
