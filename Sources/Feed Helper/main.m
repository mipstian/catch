#include <xpc/xpc.h>
#include <Foundation/Foundation.h>
#import "CTCFeedChecker.h"


int main(int argc, const char *argv[]) {
    NSXPCListener *serviceListener = NSXPCListener.serviceListener;
    CTCFeedChecker *feedChecker = CTCFeedChecker.sharedChecker;
    serviceListener.delegate = feedChecker;
    [serviceListener resume];

    return 0;
}
