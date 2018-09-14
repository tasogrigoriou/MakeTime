//
//  CalendarViewController.h
//  MakeTime
//
//  Created by Anastasios Grigoriou on 6/7/17.
//  Copyright © 2017 Grigoriou. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "EventKit/EventKit.h"

@interface CalendarViewController : UIViewController

@property (strong, nonatomic) NSArray<EKCalendar *> *customCalendars;
@property (strong, nonatomic) EKCalendar *selectedCalendar;

- (instancetype)initFromTabBar;

@end
