//
//  CoreDataHelper.h
//  SuperCoreData
//
//  Created by ernesto sanchez on 11/3/15.
//  Copyright © 2015 ernesto sanchez. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


typedef void (^SavedContextSuccess)(id success);
typedef void (^SavedContextError)(NSString *errorString, NSDictionary *errorDict);

@interface CoreDataHelper : NSObject
{
    NSManagedObjectModel *managedObjectModel;
    NSManagedObjectContext *managedObjectContext;
    NSPersistentStoreCoordinator *persistentStoreCoordinator;
    
}
@property (nonatomic, retain) NSArray *itemsInDB;
@property (nonatomic, retain) NSString *storeFileName;
@property (nonatomic, readonly) NSManagedObjectContext       *importContext;
@property (nonatomic, retain, readonly) NSManagedObjectModel *managedObjectModel;
@property (nonatomic, retain, readonly) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, retain, readonly) NSPersistentStoreCoordinator *persistentStoreCoordinator;
@property (nonatomic, readonly) NSPersistentStore            *store;

+(CoreDataHelper *)sharedModelHelper;

-(void)defineDatabaseName: (NSString *)databaseName;

-(void)setupCoreDataWithObjects:(NSArray *)objects;

-(NSArray *)getInfoForItem:(NSString *)itemName;

- (id)singleInstanceOf:(NSString *)entityName
                 where:(NSString *)condition
             isEqualTo:(id)value;

- (NSArray *)allInstancesOf:(NSString *)entityName
                      where:(NSArray *)conditions
                  isEqualto:(NSArray*)values
                  orderedBy:(NSString *)property;
- (NSString *)applicationDocumentsDirectory;

- (void)setNewInstanceFromObjectWithName:(NSString *)objectName
                            usingParams:(NSDictionary *)params
                     withMainIdentifier:(NSString *)primaryKey
                            withSuccess:(SavedContextSuccess)success
                                orError:(SavedContextError)saveError;

- (void)updateExistingInstanceFromObjectWithName:(NSString *)objectName
                                    usingParams:(NSDictionary *)params
                             withMainIdentifier:(NSString *)primaryKey
                                    withSuccess:(SavedContextSuccess)success
                                        orError:(SavedContextError)saveError;

- (void)insertObjects:(NSArray *)objects
            withName:(NSString *)entityName
  withMainIdentifier:(NSString *)primaryKey
         withSuccess:(SavedContextSuccess)success
             orError:(SavedContextError)saveError;

- (void)deleteEntity:(NSManagedObject *)entity;
- (void)deleteEntities:(NSArray *)entities
          withSuccess:(SavedContextSuccess)success
              orError:(SavedContextError)saveError;

-(NSArray *)savedObjectInstanceFromObjectWithName:(NSString *)objectName
                         OnDatabaseWithConditions:(NSArray *)conditions;


@end
