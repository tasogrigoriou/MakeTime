//
//  EventComponents.h
//  MakeTime
//
//  Created by Anastasios Grigoriou on 8/16/17.
//  Copyright © 2017 Grigoriou. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "UIKit/UIKit.h"
#import "EventKit/EventKit.h"

@interface EventComponents : NSObject

@property (copy, nonatomic) NSString *title;
@property (strong, nonatomic) EKCalendar *calendar;
@property (strong, nonatomic) NSDate *startDate;
@property (strong, nonatomic) NSDate *endDate;
@property (strong, nonatomic) UIColor *color;
@property (copy, nonatomic) NSString *identifier;

+ (EventComponents *)eventWithTitle:(NSString *)title
                           calendar:(EKCalendar *)calendar
                          startDate:(NSDate *)startDate
                            endDate:(NSDate *)endDate
                              color:(UIColor *)color
                         identifier:(NSString *)identifier;

@end
