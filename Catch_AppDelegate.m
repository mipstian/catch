//
//  Catch_AppDelegate.m
//  Catch
//
//  Created by Giorgio Calderolla on 6/12/10.
//  Copyright n\a 2010 . All rights reserved.
//

#import "Catch_AppDelegate.h"

@implementation Catch_AppDelegate

@synthesize window;

- (IBAction) orderFrontStandardAboutPanel:(id)sender {
	// Do nothing
}

/**
    Implementation of dealloc, to release the retained variables.
 */
 
- (void)dealloc {
    [window release];
	
    [super dealloc];
}


@end
