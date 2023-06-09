#import "CTCBrowser.h"
#import "CTCDefaults.h"


@implementation CTCBrowser

- (IBAction)browseService:(id)sender {
    // Launch the system browser, open the service (ShowRSS)
    [NSWorkspace.sharedWorkspace openURL:[NSURL URLWithString:kCTCDefaultsServiceURL]];
}

- (IBAction)browseWebsite:(id)sender {
    // Launch the system browser, open the applications's website
    [NSWorkspace.sharedWorkspace openURL:[NSURL URLWithString:kCTCDefaultsApplicationWebsiteURL]];
}

- (IBAction)browseHelp:(id)sender {
    // Launch the system browser, open the applications's on-line help
    [NSWorkspace.sharedWorkspace openURL:[NSURL URLWithString:kCTCDefaultsApplicationHelpURL]];
}

- (IBAction)browseFeatureRequest:(id)sender {
    // Launch the system browser, open the applications's feature request page
    [NSWorkspace.sharedWorkspace openURL:[NSURL URLWithString:kCTCDefaultsApplicationFeatureRequestURL]];
}

- (IBAction)browseBugReport:(id)sender {
    // Launch the system browser, open the applications's bug report page
    [NSWorkspace.sharedWorkspace openURL:[NSURL URLWithString:kCTCDefaultsApplicationBugReportURL]];
}

+ (void)openInBackgroundURL:(NSURL *)url {
    // Open a link without bringing app that handles it to the foreground
    [NSWorkspace.sharedWorkspace openURLs:@[url]
                  withAppBundleIdentifier:nil
                                  options:NSWorkspaceLaunchWithoutActivation
           additionalEventParamDescriptor:nil
                        launchIdentifiers:nil];
}

+ (void)openInBackgroundFile:(NSString *)file {
    // Open a file without bringing app that handles it to the foreground
    [NSWorkspace.sharedWorkspace openFile:file
                          withApplication:nil
                            andDeactivate:NO];
}

@end
