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

@property (strong, nonatomic) NSArray<NSDate *> *daysInMonth;

- (instancetype)initWithDateEvents:(NSDictionary<NSDate *, NSArray<EKEvent *> *> *)dateEvents daysInMonth:(NSArray<NSDate *> *)daysInMonth;

- (void)loadEventsModelDataWithCompletion:(void (^)(void))completion;

@end
