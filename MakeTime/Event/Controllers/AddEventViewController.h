//
//  AddEventViewController.h
//  MakeTime
//
//  Created by Anastasios Grigoriou on 6/7/17.
//  Copyright © 2017 Grigoriou. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "EventKit/EventKit.h"

@interface AddEventViewController : UIViewController

@property (strong, nonatomic) EKCalendar *calendar;
@property (assign, nonatomic) NSInteger indexOfCalendar;

@property (strong, nonatomic) NSString *eventTitle;

@property (strong, nonatomic) NSDate *senderDate;
@property (strong, nonatomic) NSDate *eventStartDate;
@property (strong, nonatomic) NSDate *eventEndDate;

@property (strong, nonatomic) NSIndexPath *repeatIndexPath;
@property (strong, nonatomic) NSString *repeatString;
@property (assign, nonatomic) NSInteger alarmIndex;
@property (strong, nonatomic) NSString *alarmString;

@property (assign, nonatomic) BOOL didPushRepeatAlertVC;

// Method to call from DatePickerTableViewCell to update the date when selected from the date picker
- (void)changeDateAboveDatePicker:(UIDatePicker *)sender;

- (instancetype)initWithCalendar:(EKCalendar *)calendar;

@end
