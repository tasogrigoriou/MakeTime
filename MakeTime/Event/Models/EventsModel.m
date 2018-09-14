//
//  EventsModel.m
//  MakeTime
//
//  Created by Anastasios Grigoriou on 9/11/18.
//  Copyright © 2018 Grigoriou. All rights reserved.
//

#import "EventsModel.h"

@implementation EventsModel

- (instancetype)initWithDateEvents:(NSDictionary<NSDate *, NSArray<EKEvent *> *> *)dateEvents daysInMonth:(NSArray<NSDate *> *)daysInMonth {
    if (self = [super init]) {
        self.dateEvents = dateEvents;
        self.daysInMonth = daysInMonth;
    }
    return self;
}

- (void)loadEventsModelDataWithCompletion:(void (^)(void))completion {
    self.indexedEvents = [self convertDateEventsToIndexedEvents:self.dateEvents];
    self.indexedDates = [self mapIndexToDate:self.indexedEvents];
    completion();
}

- (NSArray<NSArray<EKEvent *> *> *)convertDateEventsToIndexedEvents:(NSDictionary<NSDate *, NSArray<EKEvent *> *> *)dateEvents {
    NSMutableArray<NSArray<EKEvent *> *> *indexedEvents = [[NSMutableArray alloc] init];
    
    NSInteger index = 0;
    for (NSDate *day in self.daysInMonth) {
        for (NSDate *key in dateEvents) {
            if ([day isEqualToDate:key]) {
                NSArray<EKEvent *> *events = [dateEvents objectForKey:key];
                [indexedEvents insertObject:events atIndex:index];
                index++;
                break;
            }
        }
    }
    
    return (NSArray<NSArray<EKEvent *> *> *)indexedEvents;
}

- (NSDictionary<NSDate *, NSNumber *> *)mapIndexToDate:(NSArray<NSArray<EKEvent *> *> *)indexedEvents {
    NSMutableDictionary<NSDate *, NSNumber *> *indexedDates = [[NSMutableDictionary alloc] init];
    
    NSInteger index = 0;
    for (NSArray<EKEvent *> *events in indexedEvents) {
        NSDate *dateKey = [[NSCalendar currentCalendar] startOfDayForDate:[events firstObject].startDate];
        NSNumber *numValue = [NSNumber numberWithInteger:index];
        indexedDates[dateKey] = numValue;
        index++;
    }
    
    return (NSDictionary<NSDate *, NSNumber *> *)indexedDates;
}

@end
