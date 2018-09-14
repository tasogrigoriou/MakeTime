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

@property (strong, nonatomic) NSDictionary<NSDate *, NSArray<EKEvent *> *> *dateEvents;
@property (strong, nonatomic) NSArray<NSArray<EKEvent *> *> *indexedEvents;
@property (strong, nonatomic) NSDictionary<NSDate *, NSNumber *> *indexedDates;

@property (strong, nonatomic) NSArray<NSDate *> *days;

- (instancetype)initWithDateEvents:(NSDictionary<NSDate *, NSArray<EKEvent *> *> *)dateEvents days:(NSArray<NSDate *> *)days;

- (void)loadEventsModelDataWithCompletion:(void (^)(void))completion;

- (void)loadEventsDataWithStartDate:(NSDate *)startDate
                            endDate:(NSDate *)endDate
                          calendars:(NSArray<EKCalendar *> *)calendars
                         completion:(void (^)(NSDictionary<NSDate *, NSArray<EKEvent *> *> *dateEvents, NSArray<NSDate *> *sortedDays))completion;

@end
