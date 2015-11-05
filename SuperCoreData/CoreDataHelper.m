//
//  CoreDataHelper.m
//  SuperCoreData
//
//  Created by ernesto sanchez on 11/3/15.
//  Copyright © 2015 ernesto sanchez. All rights reserved.
//

#import "CoreDataHelper.h"

#define DOCUMENTS_FOLDER [NSHomeDirectory() stringByAppendingPathComponent:@"Documents"]
#define debug 1
static CoreDataHelper *_sharedHelper;

@implementation CoreDataHelper
@synthesize managedObjectContext = _managedObjectContext;
@synthesize managedObjectModel = _managedObjectModel;
@synthesize persistentStoreCoordinator = _persistentStoreCoordinator;

#pragma mark - FILES
-(void)defineDatabaseName:(NSString *)databaseName {
    NSLog(@"The database name is set to %@", databaseName);
    self.storeFileName = databaseName;
}

+(CoreDataHelper *)sharedModelHelper
{
    // structure used to test whether the block has completed or not
    static dispatch_once_t p = 0;
    
    // executes a block object once and only once for the lifetime of an application
    dispatch_once(&p, ^{
        _sharedHelper = [[self alloc] init];

    });
    
    // returns the same object each time
    return _sharedHelper;
}
#pragma mark - SETUP
- (id)init {
    if (debug==1) {
        NSLog(@"Running %@ '%@'", self.class, NSStringFromSelector(_cmd));
    }
    self = [super init];
    if (!self) {return nil;}
    self.storeFileName = @"DataModel.sqlite";
    
    _managedObjectModel = [NSManagedObjectModel mergedModelFromBundles:nil];
    _persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc]
                                   initWithManagedObjectModel:_managedObjectModel];
    _managedObjectContext = [[NSManagedObjectContext alloc]
                             initWithConcurrencyType:NSMainQueueConcurrencyType];
    [_managedObjectContext setPersistentStoreCoordinator:_persistentStoreCoordinator];
    
    
    _importContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
    [_importContext performBlockAndWait:^{
        [_importContext setPersistentStoreCoordinator:_persistentStoreCoordinator];
        [_importContext setUndoManager:nil]; // the default on iOS
    }];
    return self;
}
- (NSURL *)applicationStoresDirectory {
    if (debug==1) {
        NSLog(@"Running %@ '%@'", self.class, NSStringFromSelector(_cmd));
    }
    
    NSURL *storesDirectory =
    [[NSURL fileURLWithPath:[self applicationDocumentsDirectory]]
     URLByAppendingPathComponent:@"Stores"];
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if (![fileManager fileExistsAtPath:[storesDirectory path]]) {
        NSError *error = nil;
        if ([fileManager createDirectoryAtURL:storesDirectory
                  withIntermediateDirectories:YES
                                   attributes:nil
                                        error:&error]) {
            if (debug==1) {
                NSLog(@"Successfully created Stores directory");}
        }
        else {NSLog(@"FAILED to create Stores directory: %@", error);}
    }
    return storesDirectory;
}

- (NSURL *)storeURL {
    
    if (debug==1) {
        NSLog(@"Running %@ '%@'", self.class, NSStringFromSelector(_cmd));
    }
    return [[self applicationStoresDirectory]
            URLByAppendingPathComponent:self.storeFileName];
}

- (void)loadStore {
    if (debug==1) {
        NSLog(@"Running %@ '%@'", self.class, NSStringFromSelector(_cmd));
    }
    if (_store) {return;} // Don’t load store if it’s already loaded
    
    BOOL useMigrationManager = NO;
    if (useMigrationManager &&
        [self isMigrationNecessaryForStore:[self storeURL]]) {
        [self performBackgroundManagedMigrationForStore:[self storeURL]];
    } else {
        NSDictionary *options =
        @{
          NSMigratePersistentStoresAutomaticallyOption:@YES
          ,NSInferMappingModelAutomaticallyOption:@YES
          //,NSSQLitePragmasOption: @{@"journal_mode": @"DELETE"} // Uncomment to disable WAL journal mode
          };
        NSError *error = nil;
        _store = [_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType
                                                           configuration:nil
                                                                     URL:[self storeURL]
                                                                 options:options
                                                                   error:&error];
        if (!_store) {
            NSLog(@"Failed to add store. Error: %@", error);abort();
        }
        else         {NSLog(@"Successfully added store: %@", _store);}
    }
    
}

-(void)setupCoreDataWithObjects:(NSArray *)objects
{
    self.itemsInDB = objects;
    //[self setDefaultDataStoreAsInitialStore];
    [self loadStore];
    //  [self checkIfDefaultDataNeedsImporting];
}
#pragma mark - MIGRATION MANAGER
- (BOOL)isMigrationNecessaryForStore:(NSURL*)storeUrl {
    if (debug==1) {
        NSLog(@"Running %@ '%@'", self.class, NSStringFromSelector(_cmd));
    }
    if (![[NSFileManager defaultManager] fileExistsAtPath:[self storeURL].path]) {
        if (debug==1) {NSLog(@"SKIPPED MIGRATION: Source database missing.");}
        return NO;
    }
    NSError *error = nil;
    NSDictionary *sourceMetadata =
    [NSPersistentStoreCoordinator metadataForPersistentStoreOfType:NSSQLiteStoreType
                                                               URL:storeUrl  options: nil error:&error];
    NSManagedObjectModel *destinationModel = _persistentStoreCoordinator.managedObjectModel;
    if ([destinationModel isConfiguration:nil
              compatibleWithStoreMetadata:sourceMetadata]) {
        if (debug==1) {
            NSLog(@"SKIPPED MIGRATION: Source is already compatible");}
        return NO;
    }
    return YES;
}
- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context {
    
    if ([keyPath isEqualToString:@"migrationProgress"]) {
        
        dispatch_async(dispatch_get_main_queue(), ^{
            
            float progress =
            [[change objectForKey:NSKeyValueChangeNewKey] floatValue];
            //self.migrationVC.progressView.progress = progress;
            int percentage = progress * 100;
            NSString *string =
            [NSString stringWithFormat:@"Migration Progress: %i%%",
             percentage];
            NSLog(@"%@",string);
            //  self.migrationVC.label.text = string;
        });
    }
}

- (BOOL)replaceStore:(NSURL*)old withStore:(NSURL*)new {
    
    BOOL success = NO;
    NSError *Error = nil;
    if ([[NSFileManager defaultManager]
         removeItemAtURL:old error:&Error]) {
        
        Error = nil;
        if ([[NSFileManager defaultManager]
             moveItemAtURL:new toURL:old error:&Error]) {
            success = YES;
        }
        else {
            if (debug==1) {NSLog(@"FAILED to re-home new store %@", Error);}
        }
    }
    else {
        if (debug==1) {
            NSLog(@"FAILED to remove old store %@: Error:%@", old, Error);
        }
    }
    return success;
}
- (BOOL)migrateStore:(NSURL*)sourceStore {
    if (debug==1) {
        NSLog(@"Running %@ '%@'", self.class, NSStringFromSelector(_cmd));
    }
    BOOL success = NO;
    NSError *error = nil;
    
    // STEP 1 - Gather the Source, Destination and Mapping Model
    NSDictionary *sourceMetadata = [NSPersistentStoreCoordinator
                                    metadataForPersistentStoreOfType:NSSQLiteStoreType URL:sourceStore options:nil error:&error];
    
    NSManagedObjectModel *sourceModel =
    [NSManagedObjectModel mergedModelFromBundles:nil
                                forStoreMetadata:sourceMetadata];
    
    NSManagedObjectModel *destinModel = _managedObjectModel;
    
    NSMappingModel *mappingModel =
    [NSMappingModel mappingModelFromBundles:nil
                             forSourceModel:sourceModel
                           destinationModel:destinModel];
    
    // STEP 2 - Perform migration, assuming the mapping model isn't null
    if (mappingModel) {
        NSError *error = nil;
        NSMigrationManager *migrationManager =
        [[NSMigrationManager alloc] initWithSourceModel:sourceModel
                                       destinationModel:destinModel];
        [migrationManager addObserver:self
                           forKeyPath:@"migrationProgress"
                              options:NSKeyValueObservingOptionNew
                              context:NULL];
        
        NSURL *destinStore =
        [[self applicationStoresDirectory]
         URLByAppendingPathComponent:@"Temp.sqlite"];
        
        success =
        [migrationManager migrateStoreFromURL:sourceStore
                                         type:NSSQLiteStoreType options:nil
                             withMappingModel:mappingModel
                             toDestinationURL:destinStore
                              destinationType:NSSQLiteStoreType
                           destinationOptions:nil
                                        error:&error];
        if (success) {
            // STEP 3 - Replace the old store with the new migrated store
            if ([self replaceStore:sourceStore withStore:destinStore]) {
                if (debug==1) {
                    NSLog(@"SUCCESSFULLY MIGRATED %@ to the Current Model",
                          sourceStore.path);}
                [migrationManager removeObserver:self
                                      forKeyPath:@"migrationProgress"];
            }
        }
        else {
            if (debug==1) {NSLog(@"FAILED MIGRATION: %@",error);}
        }
    }
    else {
        if (debug==1) {NSLog(@"FAILED MIGRATION: Mapping Model is null");}
    }
    return YES; // indicates migration has finished, regardless of outcome
}
- (void)performBackgroundManagedMigrationForStore:(NSURL*)storeURL {
    if (debug==1) {
        NSLog(@"Running %@ '%@'", self.class, NSStringFromSelector(_cmd));
    }
    
    // Show migration progress view preventing the user from using the app
    /* UIStoryboard *sb = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
     self.migrationVC =
     [sb instantiateViewControllerWithIdentifier:@"migration"];
     UIApplication *sa = [UIApplication sharedApplication];
     UINavigationController *nc =
     (UINavigationController*)sa.keyWindow.rootViewController;
     [nc presentViewController:self.migrationVC animated:NO completion:nil];*/
    
    // Perform migration in the background, so it doesn't freeze the UI.
    // This way progress can be shown to the user
    dispatch_async(
                   dispatch_get_global_queue(
                                             DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
                       BOOL done = [self migrateStore:storeURL];
                       if(done) {
                           // When migration finishes, add the newly migrated store
                           dispatch_async(dispatch_get_main_queue(), ^{
                               NSError *error = nil;
                               _store =
                               [_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType
                                                                         configuration:nil
                                                                                   URL:[self storeURL]
                                                                               options:nil
                                                                                 error:&error];
                               if (!_store) {
                                   NSLog(@"Failed to add a migrated store. Error: %@",
                                         error);abort();}
                               else {
                                   NSLog(@"Successfully added a migrated store: %@",
                                         _store);}
                               //[self.migrationVC dismissViewControllerAnimated:NO
                               //completion:nil];
                               //self.migrationVC = nil;
                           });
                       }
                   });
}

#pragma mark - VALIDATION ERROR HANDLING
- (void)showValidationError:(NSError *)anError {
    
    if (anError && [anError.domain isEqualToString:@"NSCocoaErrorDomain"]) {
        NSArray *errors = nil;  // holds all errors
        NSString *txt = @""; // the error message text of the alert
        
        // Populate array with error(s)
        if (anError.code == NSValidationMultipleErrorsError) {
            errors = [anError.userInfo objectForKey:NSDetailedErrorsKey];
        } else {
            errors = [NSArray arrayWithObject:anError];
        }
        // Display the error(s)
        if (errors && errors.count > 0) {
            // Build error message text based on errors
            for (NSError * error in errors) {
                NSString *entity =
                [[[error.userInfo objectForKey:@"NSValidationErrorObject"]entity]name];
                
                NSString *property =
                [error.userInfo objectForKey:@"NSValidationErrorKey"];
                
                switch (error.code) {
                    case NSValidationRelationshipDeniedDeleteError:
                        txt = [txt stringByAppendingFormat:
                               @"%@ delete was denied because there are associated %@\n(Error Code %li)\n\n", entity, property, (long)error.code];
                        break;
                    case NSValidationRelationshipLacksMinimumCountError:
                        txt = [txt stringByAppendingFormat:
                               @"the '%@' relationship count is too small (Code %li).", property, (long)error.code];
                        break;
                    case NSValidationRelationshipExceedsMaximumCountError:
                        txt = [txt stringByAppendingFormat:
                               @"the '%@' relationship count is too large (Code %li).", property, (long)error.code];
                        break;
                    case NSValidationMissingMandatoryPropertyError:
                        txt = [txt stringByAppendingFormat:
                               @"the '%@' property is missing (Code %li).", property, (long)error.code];
                        break;
                    case NSValidationNumberTooSmallError:
                        txt = [txt stringByAppendingFormat:
                               @"the '%@' number is too small (Code %li).", property, (long)error.code];
                        break;
                    case NSValidationNumberTooLargeError:
                        txt = [txt stringByAppendingFormat:
                               @"the '%@' number is too large (Code %li).", property, (long)error.code];
                        break;
                    case NSValidationDateTooSoonError:
                        txt = [txt stringByAppendingFormat:
                               @"the '%@' date is too soon (Code %li).", property, (long)error.code];
                        break;
                    case NSValidationDateTooLateError:
                        txt = [txt stringByAppendingFormat:
                               @"the '%@' date is too late (Code %li).", property, (long)error.code];
                        break;
                    case NSValidationInvalidDateError:
                        txt = [txt stringByAppendingFormat:
                               @"the '%@' date is invalid (Code %li).", property, (long)error.code];
                        break;
                    case NSValidationStringTooLongError:
                        txt = [txt stringByAppendingFormat:
                               @"the '%@' text is too long (Code %li).", property, (long)error.code];
                        break;
                    case NSValidationStringTooShortError:
                        txt = [txt stringByAppendingFormat:
                               @"the '%@' text is too short (Code %li).", property, (long)error.code];
                        break;
                    case NSValidationStringPatternMatchingError:
                        txt = [txt stringByAppendingFormat:
                               @"the '%@' text doesn't match the specified pattern (Code %li).", property, (long)error.code];
                        break;
                    case NSManagedObjectValidationError:
                        txt = [txt stringByAppendingFormat:
                               @"generated validation error (Code %li)", (long)error.code];
                        break;
                        
                    default:
                        txt = [txt stringByAppendingFormat:
                               @"Unhandled error code %li in showValidationError method", (long)error.code];
                        break;
                }
            }
            
        }
    }
}

#pragma mark – DATA IMPORT
- (BOOL)isDefaultDataAlreadyImportedForStoreWithURL:(NSURL*)url
                                             ofType:(NSString*)type {
    if (debug==1) {
        NSLog(@"Running %@ '%@'", self.class, NSStringFromSelector(_cmd));
    }
    NSError *error;
    NSDictionary *dictionary =
    [NSPersistentStoreCoordinator metadataForPersistentStoreOfType:type
                                                               URL:url
                                                           options:nil
                                                             error:&error];
    if (error) {
        NSLog(@"Error reading persistent store metadata: %@",
              error.localizedDescription);
    }
    else {
        NSNumber *defaultDataAlreadyImported =
        [dictionary valueForKey:@"DefaultDataImported"];
        if (![defaultDataAlreadyImported boolValue]) {
            NSLog(@"Default Data has NOT already been imported");
            return NO;
        }
    }
    if (debug==1) {NSLog(@"Default Data HAS already been imported");}
    return YES;
}
- (void)checkIfDefaultDataNeedsImporting:(NSArray *)parameters {
    if (debug==1) {
        NSLog(@"Running %@ '%@'", self.class, NSStringFromSelector(_cmd));
    }
    if (![self isDefaultDataAlreadyImportedForStoreWithURL:[self storeURL]
                                                    ofType:NSSQLiteStoreType]) {
        /* [self importFromXML:[[NSBundle mainBundle]
         URLForResource:@"DefaultData" withExtension:@"xml"]];*/
        
        [self setDefaultDataAsImportedForStore:_store];
        /**/
    }
}
- (void)setDefaultDataAsImportedForStore:(NSPersistentStore*)aStore {
    if (debug==1) {
        NSLog(@"Running %@ '%@'", self.class, NSStringFromSelector(_cmd));
    }
    // get metadata dictionary
    NSMutableDictionary *dictionary =
    [NSMutableDictionary dictionaryWithDictionary:[[aStore metadata] copy]];
    
    if (debug==1) {
        NSLog(@"__Store Metadata BEFORE changes__ \n %@", dictionary);
    }
    
    // edit metadata dictionary
    [dictionary setObject:@YES forKey:@"DefaultDataImported"];
    
    // set metadata dictionary
    [self.persistentStoreCoordinator setMetadata:dictionary forPersistentStore:aStore];
    
    if (debug==1) {NSLog(@"__Store Metadata AFTER changes__ \n %@", dictionary);}
}
- (void)setDefaultDataStoreAsInitialStore {
    if (debug==1) {
        NSLog(@"Running %@ '%@'", self.class, NSStringFromSelector(_cmd));
    }
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if (![fileManager fileExistsAtPath:self.storeURL.path]) {
        NSURL *defaultDataURL =
        [NSURL fileURLWithPath:[[NSBundle mainBundle]
                                pathForResource:@"DefaultData" ofType:@"sqlite"]];
        NSError *error;
        if (![fileManager copyItemAtURL:defaultDataURL
                                  toURL:self.storeURL
                                  error:&error]) {
            NSLog(@"DefaultData.sqlite copy FAIL: %@",
                  error.localizedDescription);
        }
        else {
            NSLog(@"A copy of DefaultData.sqlite was set as the initial store for %@",
                  self.storeURL.path);
        }
    }
}

-(NSArray *)getInfoForItem:(NSString *)itemName
{
    // initializing NSFetchRequest
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    
    //Setting Entity to be Queried
    NSEntityDescription *entity = [NSEntityDescription entityForName:itemName
                                              inManagedObjectContext:self.managedObjectContext];
    [fetchRequest setEntity:entity];
    NSError* error;
    
    // Query on managedObjectContext With Generated fetchRequest
    NSArray *fetchedRecords = [self.managedObjectContext executeFetchRequest:fetchRequest error:&error];
    
    // Returning Fetched Records
    return fetchedRecords;
}

- (NSManagedObjectContext *) managedObjectContext {
    if (_managedObjectContext != nil) {
        return _managedObjectContext;
    }
    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    if (coordinator != nil) {
        _managedObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
        [_managedObjectContext setPersistentStoreCoordinator: coordinator];
    }
    
    return _managedObjectContext;
}

- (NSManagedObjectModel *)managedObjectModel {
    if (_managedObjectModel != nil) {
        return _managedObjectModel;
    }
    _managedObjectModel = [NSManagedObjectModel mergedModelFromBundles:nil];
    
    return _managedObjectModel;
}

- (NSPersistentStoreCoordinator *)persistentStoreCoordinator {
    if (persistentStoreCoordinator != nil) {
        return persistentStoreCoordinator;
    }
    
    NSURL *storeUrl = [NSURL fileURLWithPath: [[self applicationDocumentsDirectory] stringByAppendingPathComponent: @"database.sqlite"]];
    
    NSError *error = nil;
    NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:
                             [NSNumber numberWithBool:YES], NSMigratePersistentStoresAutomaticallyOption,
                             [NSNumber numberWithBool:YES], NSInferMappingModelAutomaticallyOption, nil];
    persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel: [self managedObjectModel]];
    if (![persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeUrl options:options error:&error]) {
        // Handle error
    }
    
    return persistentStoreCoordinator;
}
- (NSString *)applicationDocumentsDirectory {
    return [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
}
#pragma mark - Search methods


// Search inside the database for a specific entity. The result returns a single entity object
- (id)singleInstanceOf:(NSString *)entityName where:(NSString *)condition isEqualTo:(id)value
{
    NSManagedObjectContext *context = [self managedObjectContext];
    NSError *error;
    
    if (![context save:&error])
    {
        NSLog(@"Error: Couldn't fetch: %@", [error localizedDescription]);
    }
    
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity  = [NSEntityDescription entityForName:entityName
                                               inManagedObjectContext:context];
    [fetchRequest setEntity:entity];
    
    // If 'condition' is not nil, limit results to that condition
    if (condition && value)
    {
        NSPredicate *pred;
        if([value isKindOfClass:[NSManagedObject class]])
        {
            value = [((NSManagedObject *)value) objectID];
            pred = [NSPredicate predicateWithFormat:@"(%@ = %@)", condition, value];
        } else if ([value isKindOfClass:[NSString class]])
        {
            NSString *format  = [NSString stringWithFormat:@"%@ LIKE '%@'", condition, value];
            pred = [NSPredicate predicateWithFormat:format];
        } else {
            NSString *format  = [NSString stringWithFormat:@"%@ == %@", condition, value];
            pred = [NSPredicate predicateWithFormat:format];
        }
        [fetchRequest setPredicate:pred];
    }
    [fetchRequest setFetchLimit:1];
    NSArray *fetchedObjects = [context executeFetchRequest:fetchRequest
                                                     error:&error];
    
    return [fetchedObjects count] > 0 ? [fetchedObjects objectAtIndex:0] : nil;
}

// Search inside the database for a entities that match with conditions provided by the user. The result returns an array of entities

- (NSArray *)allInstancesOf:(NSString *)entityName
                      where:(NSArray *)conditions
                  isEqualto:(NSArray*)values
                  orderedBy:(NSString *)property
{
    NSManagedObjectContext *context = [self managedObjectContext];
    
    
    NSError *error;
    
    if (![context save:&error])
    {
        NSLog(@"Error: Couldn't fetch: %@", [error localizedDescription]);
    }
    
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity  = [NSEntityDescription entityForName:entityName
                                               inManagedObjectContext:context];
    [fetchRequest setEntity:entity];
    
    // If 'condition' is not nil, limit results to that condition
    if (conditions && values)
    {
        NSPredicate *pred;
        
        NSMutableString *conditionString;
        
        for (int x = 0; x < [conditions count]; x++) {
            id value = values[x];
            if ([value isKindOfClass:[NSNumber class]]) {
                value = [NSString stringWithFormat:@"%@", [value stringValue]];
            }
            NSString *condition = conditions[x];
            if([value isKindOfClass:[NSManagedObject class]])
            {
                value = [((NSManagedObject *)value) objectID];
                if (x > 0) {
                    [conditionString appendString:[NSString stringWithFormat: @" AND %@ = %@", condition, value]];
                }else{
                    conditionString = [[NSMutableString alloc]initWithString:[NSString stringWithFormat: @"AND %@ = %@", condition, value]];
                }
            } else if ([value isKindOfClass:[NSString class]])
            {
                if (x > 0) {
                    [conditionString appendString:[NSString stringWithFormat: @" AND %@ LIKE '%@'", condition, value]];
                    
                }else{
                    conditionString = [[NSMutableString alloc]initWithString:[NSString stringWithFormat:@"%@ LIKE '%@'", condition, value]];
                }
                
            } else {
                if (x > 0) {
                    [conditionString appendString:[NSString stringWithFormat: @" AND %@ == %@", condition, value]];
                }else{
                    conditionString = [[NSMutableString alloc]initWithString:[NSString stringWithFormat:@"%@ == %@", condition, value]];
                }
            }
        }
        NSString *finalStringFormat = [NSString stringWithFormat:@"%@", conditionString];
        
        pred = [NSPredicate predicateWithFormat:finalStringFormat];
        [fetchRequest setPredicate:pred];
        
    }
    
    // If 'property' is not nil, have the results sorted
    if (property)
    {
        NSSortDescriptor *sd = [[NSSortDescriptor alloc] initWithKey:property
                                                           ascending:YES];
        
        NSArray *sortDescriptors = [NSArray arrayWithObject:sd];
        
        [fetchRequest setSortDescriptors:sortDescriptors];
    }
    
    NSArray *fetchedObjects = [context executeFetchRequest:fetchRequest
                                                     error:&error];
    
    return fetchedObjects;
}

-(NSArray *)oldInformation:(NSDictionary *)conditions ofInstance:(NSString *)instanceName {
    NSString *keyName = [conditions allKeys][0];
    NSString *valueName = [conditions objectForKey:keyName];
    
    NSArray *oldInfo =[self allInstancesOf:instanceName where:@[keyName] isEqualto:@[valueName] orderedBy:nil];
    
    return oldInfo;
}

#pragma mark - Insertion and Update methods

-(void)setNewInstanceFromObjectWithName:(NSString *)objectName usingParams:(NSDictionary *)params withMainIdentifier:(NSString *)primaryKey withSuccess:(SavedContextSuccess)success orError:(SavedContextError)saveError {
    NSString *objectMainId = [params objectForKey:primaryKey];
    NSDictionary *identifierConditions = @{primaryKey : objectMainId};
    
    if ([[self oldInformation:identifierConditions ofInstance:objectName] count] > 0) {
        [self updateExistingInstanceFromObjectWithName:objectName usingParams:params withMainIdentifier:primaryKey withSuccess:^(id successOne) {
            success(successOne);
        } orError:^(NSString *errorString, NSDictionary *errorDict) {
            saveError(errorString, errorDict);
        }];
    }
    
    NSManagedObject *currentObject = [NSEntityDescription insertNewObjectForEntityForName:objectName inManagedObjectContext:[self managedObjectContext]];
    for (NSString *key in params){
        if (([[params objectForKey:key] length] > 0) || [[params objectForKey:key] isKindOfClass:[NSNull class]]){
            [currentObject setValue:[params objectForKey:key] forKey:key];
        }
    }
    [self saveContextWithSuccess:^(NSString *successString) {
        success(successString);
    } orError:^(NSString *errorString, NSDictionary *errorDict) {
        saveError(errorString, errorDict);
    }];
    
   // NSArray *oldInfo = [self allInstancesOf:objectName where:conditions isEqualto:<#(NSArray *)#> orderedBy:<#(NSString *)#>]
  
}

-(void)updateExistingInstanceFromObjectWithName:(NSString *)objectName usingParams:(NSDictionary *)params withMainIdentifier:(NSString *)primaryKey withSuccess:(SavedContextSuccess)success orError:(SavedContextError)saveError {
     NSString *objectMainId = [params objectForKey:primaryKey];
    NSManagedObject *currentObject = [self singleInstanceOf:objectName where:primaryKey isEqualTo:objectMainId];
    
    for (NSString *key in params){
        if (([[params objectForKey:key] length] > 0) || [[params objectForKey:key] isKindOfClass:[NSNull class]]){
            if (![key isEqualToString:primaryKey]){
                
                [currentObject setValue:[params objectForKey:key] forKey:key];
            }
        }
    }
    NSLog(@"This is the object that should be saved %@", currentObject.description);
    NSLog(@"This are the values that changed %@", currentObject.changedValues);
   
    [self saveContextWithSuccess:^(NSString *successString) {
        success(successString);
    } orError:^(NSString *errorString, NSDictionary *errorDict) {
        saveError(errorString, errorDict);
    }];
}

-(void)insertObjects:(NSArray *)objects withName:(NSString *)entityName withMainIdentifier:(NSString *)primaryKey withSuccess:(SavedContextSuccess)success orError:(SavedContextError)saveError {
    NSInteger count = 0;
    for (NSDictionary *object in objects) {
        [self setNewInstanceFromObjectWithName:entityName usingParams:object withMainIdentifier:primaryKey withSuccess:^(id successIn) {
            NSLog(@"Successfully saved object");
        } orError:^(NSString *errorString, NSDictionary *errorDict) {
            saveError(errorString, errorDict);
            return;
        }];
        count++;
    }
    success([NSString stringWithFormat:@"Successfully inserted %ld objects", count]);
}

-(NSArray *)savedObjectInstanceFromObjectWithName:(NSString *)objectName OnDatabaseWithConditions:(NSArray *)conditions
{
   /* NSMutableArray *conditionsKeys   = [[NSMutableArray alloc] init];
    NSMutableArray *conditionsValues = [[NSMutableArray alloc] init];
    for (NSDictionary *conditionDictionary in conditions) {
        for (NSString *key in conditionDictionary) {
            [conditionsKeys addObject:key];
            [conditionsKeys addObject:[conditionDictionary objectForKey:conditionsKeys]];
        }
    }*/
    
    NSArray *savedObjects = [self allInstancesOf:objectName where:nil isEqualto:nil orderedBy:nil];
    return savedObjects;
}


- (void)saveContextWithSuccess:(SavedContextSuccess)success orError:(SavedContextError)saveError
{
    NSError *error = nil;
    
    NSManagedObjectContext *context = _managedObjectContext;
    
    
    if (context != nil)
    {
        if ([context hasChanges] && ![context save:&error])
        {
            /*
             Replace this implementation with code to handle the error appropriately.
             
             abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
             */
            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
            saveError(error.description, [error userInfo]);
            abort();
        }
    }
    success(@"saved successfully");
}

#pragma mark - Delete Methods
- (void)deleteEntity:(NSManagedObject *)entity
{
    [self.managedObjectContext deleteObject:entity];
    [self saveContextWithSuccess:^(id success) {
        NSLog(@"%@", success);
    } orError:^(NSString *errorString, NSDictionary *errorDict) {
        NSLog(@"%@", errorString);
    }];
}

-(void)deleteEntities:(NSArray *)entities
          withSuccess:(SavedContextSuccess)success
              orError:(SavedContextError)saveError {
    NSInteger count = 0;
    for (NSManagedObject *entity in entities) {
        if ([entity isKindOfClass:[NSManagedObject class]]){
            [self deleteEntity:entity];
        }else {
            saveError(@"The object you're trying to remove is not a valid Entity", nil);
        }
    }
    success([NSString stringWithFormat:@"Successfully removed %ld objects", count]);
}

@end
