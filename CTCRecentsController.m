#import "CTCRecentsController.h"
#import "CTCDefaults.h"
#import "CTCScheduler.h"
#import "CTCRecentsCellView.h"


@interface CTCRecentsController ()

@property (weak) IBOutlet NSTableView *table;

@property (strong, nonatomic) NSDateFormatter *downloadDateFormatter;

@end

@implementation CTCRecentsController

- (void)awakeFromNib {
    // Create a formatter for torrent download dates
    self.downloadDateFormatter = NSDateFormatter.new;
    self.downloadDateFormatter.timeStyle = NSDateFormatterShortStyle;
    self.downloadDateFormatter.dateStyle = NSDateFormatterShortStyle;
    self.downloadDateFormatter.doesRelativeDateFormatting = YES;
    
    [self setupObservers];
}

- (void)setupObservers {
    __weak typeof(self) weakSelf = self;
    
    [NSNotificationCenter.defaultCenter addObserverForName:kCTCSchedulerLastUpdateStatusNotificationName
                                                    object:CTCScheduler.sharedScheduler
                                                     queue:nil
                                                usingBlock:^(NSNotification *notification) {
                                                    [weakSelf.table reloadData];
                                                }];
}

- (IBAction)showWindow:(id)sender {
    [self.table reloadData];
    [NSApp activateIgnoringOtherApps:YES];
    [super showWindow:sender];
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
    return CTCDefaults.downloadHistory.count;
}

- (IBAction)downloadRecentItemAgain:(NSButton *)senderButton {
    NSUInteger clickedRow = [self.table rowForView:senderButton];
    NSDictionary *recentToDownload = CTCDefaults.downloadHistory[clickedRow];
    if (!recentToDownload) return;
    
    BOOL isMagnetLink = [recentToDownload[@"isMagnetLink"] boolValue];
    if (isMagnetLink) {
        [NSWorkspace.sharedWorkspace openURL:[NSURL URLWithString:recentToDownload[@"url"]]];
    }
    else {
        [CTCScheduler.sharedScheduler downloadFile:recentToDownload];
    }
}

//    // Also refresh the list of recently downloaded torrents
//    // Get the full list
//    NSArray *downloadHistory = CTCDefaults.downloadHistory;
//
//    // Get last 9 elements  (changed from 10 so everything aligns nicer in the menu.. small tweak)
//    NSUInteger recentsCount = MIN(downloadHistory.count, 9U);
//    NSArray *recents = [downloadHistory subarrayWithRange:NSMakeRange(0U, recentsCount)];
//
//    // Clear menu
//    [self.menuRecentTorrents.submenu removeAllItems];
//
//    // Add new items
//    [recents enumerateObjectsUsingBlock:^(NSDictionary *recent, NSUInteger index, BOOL *stop) {
//        NSString *menuTitle = [NSString stringWithFormat:@"%lu %@", index + 1, recent[@"title"]];
//        NSMenuItem *recentMenuItem = [[NSMenuItem alloc] initWithTitle:menuTitle
//                                                                action:NULL
//                                                         keyEquivalent:@""];
//
//        recentMenuItem.submenu = [self submenuForRecentItem:recent atIndex:index];
//        [self.menuRecentTorrents.submenu addItem:recentMenuItem];
//    }];
//
//    // Put the Show in finder menu back
//    [self.menuRecentTorrents.submenu addItem:self.menuShowInFinder];

//    // Create a "download again" item
//    NSMenuItem *downloadAgainItem = [[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"redownload", @"Button to download a downloaded torrent file again")
//                                                               action:@selector(downloadRecentItemAgain:)
//                                                        keyEquivalent:@""];
//    downloadAgainItem.target = self;
//    downloadAgainItem.tag = index;
//    [submenu addItem:downloadAgainItem];
//
//    // Create a disabled item with the download date, if available
//    NSDate *downloadDate = (NSDate *)recent[@"date"];
//    if (downloadDate) {
//        // it may be interesting to have a bit more structure or intelligence to showing the dates for recent
//        // items (just stuff this week based on preference?), or show the date in the list.. this solves
//        // the problem of "how recent was recent?" tho with the tooltip.
//        NSString *relativeDownloadDateDescription = [self.downloadDateFormatter stringFromDate:downloadDate];
//        NSMenuItem *downloadDateItem = [[NSMenuItem alloc] initWithTitle:relativeDownloadDateDescription
//                                                                  action:NULL
//                                                           keyEquivalent:@""];
//        downloadAgainItem.enabled = NO;
//        [submenu addItem:downloadDateItem];
//    }

- (NSView *)tableView:(NSTableView *)tableView
   viewForTableColumn:(NSTableColumn *)tableColumn
                  row:(NSInteger)row {
    NSDictionary *recent = CTCDefaults.downloadHistory[row];
    
    CTCRecentsCellView *cell = [tableView makeViewWithIdentifier:@"RecentCell" owner:self];
    
    cell.textField.stringValue = recent[@"title"];
    
    NSDate *downloadDate = (NSDate *)recent[@"date"];
    cell.downloadDateTextField.stringValue = downloadDate ? [self.downloadDateFormatter stringFromDate:downloadDate] : @"";
    return cell;
}

- (BOOL)selectionShouldChangeInTableView:(NSTableView *)tableView {
    return NO;
}

- (void)dealloc {
    [NSNotificationCenter.defaultCenter removeObserver:self];
}

@end
