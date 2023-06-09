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
        // Open magnet links without bring app that handles them to the foreground
        NSArray* urls = [NSArray arrayWithObject:[NSURL URLWithString:recentToDownload[@"url"]]];
        [[NSWorkspace sharedWorkspace] openURLs:urls withAppBundleIdentifier:nil 
            options:NSWorkspaceLaunchWithoutActivation additionalEventParamDescriptor:nil launchIdentifiers:nil];
    }
    else {
        [CTCScheduler.sharedScheduler downloadFile:recentToDownload
                                        completion:^(NSDictionary *downloadedFile, NSError *error) {
                if (downloadedFile && CTCDefaults.shouldOpenTorrentsAutomatically) {
                    [NSWorkspace.sharedWorkspace openFile:downloadedFile[@"torrentFilePath"]];
                }
         }];
    }
}

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
