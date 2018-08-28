//
//  EventComponents.m
//  MakeTime
//
//  Created by Anastasios Grigoriou on 8/16/17.
//  Copyright © 2017 Grigoriou. All rights reserved.
//

#import "EventComponents.h"

@implementation EventComponents

+ (EventComponents *)eventWithTitle:(NSString *)title
                           calendar:(EKCalendar *)calendar
                          startDate:(NSDate *)startDate
                            endDate:(NSDate *)endDate
                              color:(UIColor *)color
                         identifier:(NSString *)identifier {
    EventComponents *eventComponents = [EventComponents new];
    eventComponents.title = title;
    eventComponents.calendar = calendar;
    eventComponents.startDate = startDate;
    eventComponents.endDate = endDate;
    eventComponents.color = color;
    eventComponents.identifier = identifier;
    
    return eventComponents;
}

@end
