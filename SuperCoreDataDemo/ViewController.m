//
//  ViewController.m
//  SuperCoreDataDemo
//
//  Created by ernesto sanchez on 11/4/15.
//  Copyright © 2015 ernesto sanchez. All rights reserved.
//

#import "ViewController.h"
#import "Employee.h"
#import "EmployeeTableViewCell.h"

@interface ViewController ()<UITextFieldDelegate>
@property (nonatomic) CoreDataHelper *sharedHelper;
@property (weak, nonatomic) IBOutlet UITableView *tblEmployees;
@property (weak, nonatomic) IBOutlet UITextField *txtEmployeeId;
@property (weak, nonatomic) IBOutlet UITextField *txtEmployeeName;
@property (weak, nonatomic) IBOutlet UITextField *txtEmployeeLastName;
@property (weak, nonatomic) IBOutlet UITextField *txtEmployeePosition;
@property (weak, nonatomic) IBOutlet UIButton *btnRegister;
@property (weak, nonatomic) IBOutlet UIButton *btnDelete;
@property (nonatomic) NSArray *currentEmployees;
@property (nonatomic) Employee *selectedEmployee;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self prepareUI];
    self.sharedHelper = [(AppDelegate *)[[UIApplication sharedApplication] delegate] cdh];
    
    [self retrieveSavedEmployees];
    self.btnDelete.enabled = NO;
}

-(void)prepareUI {
    self.txtEmployeeId.delegate = self;
    self.txtEmployeeName.delegate = self;
    self.txtEmployeeLastName.delegate = self;
    self.txtEmployeePosition.delegate = self;
    [self.btnRegister addTarget:self action:@selector(insertEmployee:) forControlEvents:UIControlEventTouchUpInside];
}


-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
    return (self.currentEmployees.count > 0) ? self.currentEmployees.count : 1;
}

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    EmployeeTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"employeeCell"];
    if (self.currentEmployees.count > 0) {
        Employee *theEmployee = [self.currentEmployees objectAtIndex:indexPath.row];
        [cell.lblemployeeId setText:[NSString stringWithFormat:@"ID: %@", theEmployee.idEmployee]];
        [cell.lblEmployeeName setText:[NSString stringWithFormat:@"Name: %@",theEmployee.name]];
        [cell.lblEmployeeLastName setText:[NSString stringWithFormat:@"Last Name: %@",theEmployee.lastName]];
        [cell.lblEmployeePosition setText:[NSString stringWithFormat:@"Position: %@",theEmployee.position]];
    }else{
        [cell.lblEmployeeName setText:@"No Employees Registered"];
        [cell.lblemployeeId setText:@""];
        [cell.lblEmployeeLastName setText:@""];
        [cell.lblEmployeePosition setText:@""];
    }
    
    return cell;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    self.selectedEmployee = [self.currentEmployees objectAtIndex:indexPath.row];
    [self.txtEmployeeId setText: self.selectedEmployee.idEmployee];
    [self.txtEmployeeName setText:self.selectedEmployee.name];
    [self.txtEmployeeLastName setText:self.selectedEmployee.lastName];
    [self.txtEmployeePosition setText:self.selectedEmployee.position];
    self.btnDelete.enabled = YES;
    [self.btnRegister setTitle:@"Update" forState:UIControlStateNormal];
}

#pragma mark - Super Core Data Methods

-(void)retrieveSavedEmployees {
    self.currentEmployees = [self.sharedHelper savedObjectInstanceFromObjectWithName:@"Employee" OnDatabaseWithConditions:nil];
    [self.tblEmployees reloadData];
}

-(void)insertEmployee:(UIButton *)sender {
    BOOL isNew = ([sender.currentTitle isEqualToString:@"Register"]) ? YES : NO;
    NSDictionary *employeeDict = [self newEmployee];
    __weak typeof(self) weakSelf = self;
    if (employeeDict) {
        if (isNew) {
            [self.sharedHelper setNewInstanceFromObjectWithName:@"Employee" usingParams:employeeDict withMainIdentifier:@"idEmployee" withSuccess:^(id success) {
                NSLog(@"Successfully registered new employee");
                [weakSelf retrieveSavedEmployees];
            } orError:^(NSString *errorString, NSDictionary *errorDict) {
                NSLog(@"There was an error updating the employee");
            }];
        }else{
            [self.sharedHelper updateExistingInstanceFromObjectWithName:@"Employee" usingParams:employeeDict withMainIdentifier:@"idEmployee" withSuccess:^(id success) {
                 NSLog(@"Successfully updated new employee");
                [weakSelf retrieveSavedEmployees];
            } orError:^(NSString *errorString, NSDictionary *errorDict) {
                 NSLog(@"There was an error updating the employee");
            }];
        }
    }else{
        NSLog(@"You may be missing some required textfields");
    }
   
}

-(NSDictionary *)newEmployee {
    if ((self.txtEmployeeId.text.length > 0) &&
        (self.txtEmployeeName.text.length > 0) &&
        (self.txtEmployeeLastName.text.length > 0) &&
        (self.txtEmployeePosition.text.length > 0)) {
        NSDictionary *employee = @{@"idEmployee" : self.txtEmployeeId.text,
                                   @"name": self.txtEmployeeName.text,
                                   @"lastName": self.txtEmployeeLastName.text,
                                   @"position": self.txtEmployeePosition.text
                                   };
        return employee;
    }
    
    
    return nil;
}

#pragma mark - Textfield Delegate Methods

-(BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    BOOL hasNextTxt = NO;
    UITextField *view =(UITextField *)[self.view viewWithTag:textField.tag + 1];
    if (!view){
        [textField resignFirstResponder];
    }else{
        hasNextTxt = YES;
        [view becomeFirstResponder];
    }
    UIScrollView *scrollView;
    if ([textField.superview isKindOfClass:[UIScrollView class]]) {
        scrollView = (UIScrollView *)textField.superview;
       //self.hasScrollView = YES;
        scrollView.scrollEnabled = NO;
    }
    //[textField resignFirstResponder];
    [UIView animateWithDuration:0.9
                          delay:0.0
                        options:UIViewAnimationOptionCurveEaseOut
                     animations:^{
                         if (!hasNextTxt) {
                              self.view.frame = CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height);
                            /* if (self.hasScrollView) {
                                 [scrollView setContentOffset:CGPointMake(0, 0)];
                             }else{
                             
                             }*/
                         }
                     }
                     completion:^(BOOL finished) {
                     }
     
     ];
    return YES;
}

-(void)textFieldDidEndEditing:(UITextField *)textField
{
    [textField resignFirstResponder];
    BOOL hasNextTxt = NO;
    
    UITextField *view =(UITextField *)[self.view viewWithTag:textField.tag + 1];
    if (!view){
        [textField resignFirstResponder];
    }else{
        hasNextTxt = YES;
        [view becomeFirstResponder];
    }
    UIScrollView *scrollView;
    if ([textField.superview isKindOfClass:[UIScrollView class]]) {
        scrollView = (UIScrollView *)textField.superview;
        //self.hasScrollView = YES;
        scrollView.scrollEnabled = YES;
    }
    //[textField resignFirstResponder];
    [UIView animateWithDuration:0.6
                          delay:0.0
                        options:UIViewAnimationOptionCurveEaseOut
                     animations:^{
                         if (!hasNextTxt) {
                               self.view.frame = CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height);
                             /*if (self.hasScrollView) {
                                 [scrollView setContentOffset:CGPointMake(0, 50)];
                             }else{
                                 self.view.frame = CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height);
                             }*/
                         }
                     }
                     completion:^(BOOL finished) {
                     }
     
     ];
    //return YES;
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
