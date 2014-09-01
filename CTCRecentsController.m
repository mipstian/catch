#import "CTCRecentsController.h"
#import "CTCDefaults.h"


@interface CTCRecentsController ()
@property (weak) IBOutlet NSTableView *table;
@end

@implementation CTCRecentsController

- (IBAction)showWindow:(id)sender {
    [self.table reloadData];
    [NSApp activateIgnoringOtherApps:YES];
    [super showWindow:sender];
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
    return CTCDefaults.downloadHistory.count;
}

@end
