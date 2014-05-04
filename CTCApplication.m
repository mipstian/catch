#import "CTCApplication.h"


@implementation CTCApplication

/**
    @brief Reimplement basic cut/copy/paste/undo/select all events
    @see http://stackoverflow.com/questions/970707/cocoa-keyboard-shortcuts-in-dialog-without-an-edit-menu
 */
- (void)sendEvent:(NSEvent *)event {
    if (event.type == NSKeyDown) {
        if ((event.modifierFlags & NSDeviceIndependentModifierFlagsMask) == NSCommandKeyMask) {
            if ([event.charactersIgnoringModifiers isEqualToString:@"x"]) {
                if ([self sendAction:@selector(cut:) to:nil from:self]) return;
            }
            else if ([event.charactersIgnoringModifiers isEqualToString:@"c"]) {
                if ([self sendAction:@selector(copy:) to:nil from:self]) return;
            }
            else if ([event.charactersIgnoringModifiers isEqualToString:@"v"]) {
                if ([self sendAction:@selector(paste:) to:nil from:self]) return;
            }
            else if ([event.charactersIgnoringModifiers isEqualToString:@"z"]) {
                if ([self sendAction:NSSelectorFromString(@"undo:") to:nil from:self]) return;
            }
            else if ([event.charactersIgnoringModifiers isEqualToString:@"a"]) {
                if ([self sendAction:@selector(selectAll:) to:nil from:self]) return;
            }
        }
        else if ((event.modifierFlags & NSDeviceIndependentModifierFlagsMask) == (NSCommandKeyMask | NSShiftKeyMask)) {
            if ([event.charactersIgnoringModifiers isEqualToString:@"Z"]) {
                if ([self sendAction:NSSelectorFromString(@"redo:") to:nil from:self]) return;
            }
        }
    }
    [super sendEvent:event];
}

@end
