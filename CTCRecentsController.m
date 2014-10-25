#import "CTCRecentsController.h"
#import "CTCDefaults.h"
#import "CTCScheduler.h"
#import "CTCRecentsCellView.h"
#import "CTCBrowser.h"


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
                                                    if (weakSelf) [weakSelf.table reloadData];
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
        [CTCBrowser openInBackgroundURL:[NSURL URLWithString:recentToDownload[@"url"]]];
    }
    else {
        [CTCScheduler.sharedScheduler downloadFile:recentToDownload
                                        completion:^(NSDictionary *downloadedFile, NSError *error) {
                if (downloadedFile && CTCDefaults.shouldOpenTorrentsAutomatically) {
                    [CTCBrowser openInBackgroundFile:downloadedFile[@"torrentFilePath"]];
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
