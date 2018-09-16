//
//  EventsModel.h
//  MakeTime
//
//  Created by Anastasios Grigoriou on 9/11/18.
//  Copyright © 2018 Grigoriou. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "EventKit/EventKit.h"

@interface EventsModel : NSObject

@property (strong, nonatomic) NSArray<NSDate *> *days;

@property (strong, nonatomic) NSDictionary<NSDate *, NSArray<EKEvent *> *> *dateEvents;
@property (strong, nonatomic) NSArray<NSDate *> *sortedDays;

@property (strong, nonatomic) NSDictionary<NSDate *, NSNumber *> *dateSections;

- (void)loadEventsDataModelWithStartDate:(NSDate *)startDate
                                 endDate:(NSDate *)endDate
                               calendars:(NSArray<EKCalendar *> *)calendars
                              completion:(void (^)(void))completion;

- (void)mapDateToSectionIndex:(NSDictionary<NSDate *, NSArray<EKEvent *> *> *)dateEvents;

@end
