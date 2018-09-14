//
//  EventsViewController.h
//  MakeTime
//
//  Created by Anastasios Grigoriou on 9/13/18.
//  Copyright © 2018 Grigoriou. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "EventKit/EventKit.h"

@interface EventsViewController : UIViewController

- (instancetype)initWithCalendar:(EKCalendar *)calendar;

@end
