//
//  Catch_AppDelegate.h
//  Catch
//
//  Created by Giorgio Calderolla on 6/12/10.
//  Copyright n\a 2010 . All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface Catch_AppDelegate : NSObject 
{
    NSWindow *window;
    
    NSPersistentStoreCoordinator *persistentStoreCoordinator;
    NSManagedObjectModel *managedObjectModel;
    NSManagedObjectContext *managedObjectContext;
}

@property (nonatomic, retain) IBOutlet NSWindow *window;

@property (nonatomic, retain, readonly) NSPersistentStoreCoordinator *persistentStoreCoordinator;
@property (nonatomic, retain, readonly) NSManagedObjectModel *managedObjectModel;
@property (nonatomic, retain, readonly) NSManagedObjectContext *managedObjectContext;

- (IBAction)saveAction:sender;
- (IBAction)orderFrontStandardAboutPanel:(id)sender;

@end
