//
//  EmployeeTableViewCell.h
//  SuperCoreData
//
//  Created by ernesto sanchez on 11/4/15.
//  Copyright © 2015 ernesto sanchez. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface EmployeeTableViewCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UILabel *lblemployeeId;
@property (weak, nonatomic) IBOutlet UILabel *lblEmployeeName;
@property (weak, nonatomic) IBOutlet UILabel *lblEmployeeLastName;
@property (weak, nonatomic) IBOutlet UILabel *lblEmployeePosition;

@end
