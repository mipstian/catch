#import <Cocoa/Cocoa.h>


@interface CTCRecentsCellView : NSTableCellView

@property (weak, nonatomic) IBOutlet NSTextField *downloadDateTextField;
@property (weak, nonatomic) IBOutlet NSButton *downloadAgainButton;

@end
