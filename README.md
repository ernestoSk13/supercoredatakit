# SuperCoreDataKit
SuperCoreDataKit is a framework made specially to simplify the process of inserting, updating and deleting objects
from Core Data. It handles all the process of preparing the sqlite database and preparing it in case you have to
change the current model version. 

Some of the features that you can take advantage of are:

· Define database's name.<br>
· Setup the objects that will be stored inside the database.<br>
· Insert/Update/Delete objects in an specific entity by providing it's name, parameters, and it's primary key or
  main identifier.<br>
· Filter results by different conditions in an Array or a single instance.<br>
· Retrieve Application Documents Directory Path.<br>
· Multiple Insertion /Deletion / Updates<br>

#SuperCoreDataDemo
<p> In the SuperCoreDataDemo file you will fin an example of how the framework is used. Take special attention
of how the framework's helper instance is just called once and it's setted up in a singleton when the app launches
(See AppDelegate.m inside the project for details)</p>

#Installing the framework in your project
<p>· Open the xcode project named SuperCoreData <br>
· Once you are inside be sure to select the SuperCoreData framework and build it.<br>
· On the project folders look for the one named "Products", right click it and select "Show in Finder"<br>
· Notice that there will be a file with a ".framework" suffix. (<b>Important:</b> If you build for a simulator, 
the simulator will only work for simulator. Same case with device. This will be fixes in the next version).<br>
· Drag the <b>SuperCoreData.framework</b> file to your project and add it to the Embedded Binaries on the project's
general settings. <br>
· Import the framework in the AppDelegate.h file (#import <SuperCoreData/CoreDataHelper.h>)</p>

Main methods
<p>
// Search inside the database for a specific entity. The result returns a single entity object <br>
- (id)singleInstanceOf:(NSString *)entityName
                 where:(NSString *)condition
             isEqualTo:(id)value;<br>
<br>
// Search inside the database for a entities that match with conditions provided by the user. The result returns an array of entities<br>
- (NSArray *)allInstancesOf:(NSString *)entityName
                      where:(NSArray *)conditions
                  isEqualto:(NSArray*)values
                  orderedBy:(NSString *)property;<br><br>
//Insert a single instance of an entity. The user specifies the entity name, a dictionary with the name of the property and its value. Once the insertion is done the method returnes a success string. In case the instance already exists it calls the update methods<br>
- (void)setNewInstanceFromObjectWithName:(NSString *)objectName
                            usingParams:(NSDictionary *)params
                     withMainIdentifier:(NSString *)primaryKey
                            withSuccess:(SavedContextSuccess)success
                                orError:(SavedContextError)saveError;<br><br>
//Update a single instance of an entity. Same process as the insertion method.<br>
- (void)updateExistingInstanceFromObjectWithName:(NSString *)objectName
                                    usingParams:(NSDictionary *)params
                             withMainIdentifier:(NSString *)primaryKey
                                    withSuccess:(SavedContextSuccess)success
                                        orError:(SavedContextError)saveError;<br><br>
//Multiple insertion. The method receives an Array of NSDictionaries with the values that should be saved. If an object inside the array already exists it will be updated.<br>
- (void)insertObjects:(NSArray *)objects
            withName:(NSString *)entityName
  withMainIdentifier:(NSString *)primaryKey
         withSuccess:(SavedContextSuccess)success
             orError:(SavedContextError)saveError;<br><br>
//Remove a single instance of an existing entity<br>
- (void)deleteEntity:(NSManagedObject *)entity;<br><br>
//Remove multiple instances. The method receives an NSManagedObject Array. 
- (void)deleteEntities:(NSArray *)entities
          withSuccess:(SavedContextSuccess)success
              orError:(SavedContextError)saveError;


</p>

#Next Features

· Universal Framework<br>
