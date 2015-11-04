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

#SuperCoreDataDemo
<p> In the SuperCoreDataDemo file you will fin an example of how the framework is used. Take special attention
of how the framework's helper instance is just called once and it's setted up in a singleton when the app launches
(See AppDelegate.m inside the project for details)</p>

#Installing the framework in your project
· Open the xcode project named SuperCoreData <br>
· Once you are inside be sure to select the SuperCoreData framework and build it.<br>
· On the project folders look for the one named "Products", right click it and select "Show in Finder"<br>
· Notice that there will be a file with a ".framework" suffix. (<b>Important:</b> If you build for a simulator, 
the simulator will only work for simulator. Same case with device. This will be fixes in the next version).<br>
· Drag the <b>SuperCoreData.framework</b> file to your project and add it to the Embedded Binaries on the project's
general settings. <br>
· Import the framework in the AppDelegate.h file (#import <SuperCoreData/CoreDataHelper.h>




  
