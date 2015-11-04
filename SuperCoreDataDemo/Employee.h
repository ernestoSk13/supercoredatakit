//
//  Employee.h
//  SuperCoreData
//
//  Created by ernesto sanchez on 11/4/15.
//  Copyright © 2015 ernesto sanchez. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface Employee : NSManagedObject

@property (nullable, nonatomic, retain) NSString *name;
@property (nullable, nonatomic, retain) NSString *lastName;
@property (nullable, nonatomic, retain) NSString *idEmployee;
@property (nullable, nonatomic, retain) NSString *position;

@end


