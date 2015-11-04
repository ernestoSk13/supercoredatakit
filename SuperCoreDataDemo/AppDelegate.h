//
//  AppDelegate.h
//  SuperCoreDataDemo
//
//  Created by ernesto sanchez on 11/4/15.
//  Copyright © 2015 ernesto sanchez. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>
#import <SuperCoreData/CoreDataHelper.h>

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;

@property (readonly, strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (readonly, strong, nonatomic) NSManagedObjectModel *managedObjectModel;
@property (readonly, strong, nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;
@property (nonatomic, strong, readonly) CoreDataHelper *coreDataHelper;
- (CoreDataHelper*)cdh;

- (void)saveContext;
- (NSURL *)applicationDocumentsDirectory;


@end

