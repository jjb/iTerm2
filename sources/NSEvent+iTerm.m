//
//  NSEvent+iTerm.m
//  iTerm2
//
//  Created by George Nachman on 11/24/14.
//
//

#import "NSEvent+iTerm.h"

#import "iTermAdvancedSettingsModel.h"

#import <Carbon/Carbon.h>

@implementation NSEvent (iTerm)

- (NSEvent *)eventWithEventType:(CGEventType)eventType {
    CGEventRef cgEvent = [self CGEvent];
    CGPoint globalCoord = CGEventGetLocation(cgEvent);
    // Because the fakeEvent will have a nil window, adjust the coordinate to report a proper
    // locationInWindow. Not quite sure what's going on here, but this works :/.
    NSPoint windowOrigin = self.window.frame.origin;
    globalCoord.x -= windowOrigin.x;
    globalCoord.y -= self.window.screen.frame.origin.y;
    globalCoord.y += windowOrigin.y;

    CGEventRef fakeCgEvent = CGEventCreateMouseEvent(NULL,
                                                     eventType,
                                                     globalCoord,
                                                     2);
    int64_t clickCount = 1;
    if (self.type == NSEventTypeLeftMouseDown || self.type == NSEventTypeLeftMouseUp ||
        self.type == NSEventTypeRightMouseDown || self.type == NSEventTypeRightMouseUp ||
        self.type == NSEventTypeOtherMouseDown || self.type == NSEventTypeOtherMouseUp) {
        clickCount = [self clickCount];
    }
    CGEventSetIntegerValueField(fakeCgEvent, kCGMouseEventClickState, clickCount);
    CGEventSetFlags(fakeCgEvent, CGEventGetFlags(cgEvent));
    NSEvent *fakeEvent = [NSEvent eventWithCGEvent:fakeCgEvent];
    CFRelease(fakeCgEvent);
    return fakeEvent;
}

- (NSEvent *)mouseUpEventFromGesture {
    return [self eventWithEventType:kCGEventLeftMouseUp];
}

- (NSEvent *)mouseDownEventFromGesture {
    return [self eventWithEventType:kCGEventLeftMouseDown];
}

- (NSEvent *)eventWithButtonNumber:(NSInteger)buttonNumber {
    NSEvent *original = [NSEvent mouseEventWithType:NSEventTypeOtherMouseDown
                                           location:self.locationInWindow
                                      modifierFlags:self.modifierFlags
                                          timestamp:self.timestamp
                                       windowNumber:self.windowNumber
                                            context:[NSGraphicsContext currentContext]
                                        eventNumber:self.eventNumber
                                         clickCount:self.clickCount
                                           pressure:self.pressure];
    CGEventRef cgEvent = [original CGEvent];
    CGEventRef modifiedCGEvent = CGEventCreateCopy(cgEvent);
    CGEventSetIntegerValueField(modifiedCGEvent, kCGMouseEventButtonNumber, buttonNumber);
    NSEvent *fakeEvent = [NSEvent eventWithCGEvent:modifiedCGEvent];
    CFRelease(modifiedCGEvent);
    return fakeEvent;
}

- (NSEventModifierFlags)it_modifierFlags {
    if (![iTermAdvancedSettingsModel workAroundNumericKeypadBug]) {
        return self.modifierFlags;
    }
    
    switch (self.type) {
        case NSEventTypeKeyUp:
        case NSEventTypeKeyDown:
            break;
        default:
            return self.modifierFlags;
    }

    switch (self.keyCode) {
        case kVK_ANSI_KeypadEquals:
            return self.modifierFlags | NSEventModifierFlagNumericPad;
            
        default:
            return self.modifierFlags;
    }
}

@end
