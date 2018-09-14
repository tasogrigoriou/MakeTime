//
//  EventsModel.m
//  MakeTime
//
//  Created by Anastasios Grigoriou on 9/11/18.
//  Copyright © 2018 Grigoriou. All rights reserved.
//

#import "EventsModel.h"
#import "EventManager.h"

@implementation EventsModel

- (instancetype)initWithDateEvents:(NSDictionary<NSDate *, NSArray<EKEvent *> *> *)dateEvents days:(NSArray<NSDate *> *)days {
    if (self = [super init]) {
        self.dateEvents = dateEvents;
        self.days = days;
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
    NSMutableArray<EKEvent *> *allEvents = [NSMutableArray array];
    
    NSInteger index = 0;
    for (NSDate *day in self.days) {
        for (NSDate *key in dateEvents) {
            if ([day isEqualToDate:key]) {
                NSArray<EKEvent *> *events = [dateEvents objectForKey:key];
                NSMutableArray<EKEvent *> *mutableEvents = [NSMutableArray array];
                for (EKEvent *event in events) {
                    if ([allEvents containsObject:event]) {
                        continue;
                    } else {
                        [mutableEvents addObject:event];
                        [allEvents addObject:event];
                    }
                }
                if ([mutableEvents count] > 0) {
                    [indexedEvents insertObject:(NSArray *)mutableEvents atIndex:index];
                    index++;
                    break;
                }
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

- (void)loadEventsDataWithStartDate:(NSDate *)startDate
                            endDate:(NSDate *)endDate
                          calendars:(NSArray<EKCalendar *> *)calendars
                         completion:(void (^)(void))completion {
    EventManager *eventManager = [EventManager sharedManager];
    NSDate *start = [[NSCalendar currentCalendar] startOfDayForDate:startDate];
    NSDate *end = [[NSCalendar currentCalendar] startOfDayForDate:[NSDate dateWithTimeIntervalSinceNow:[[NSDate distantFuture] timeIntervalSinceReferenceDate]]];
    NSPredicate *fetchCalendarEvents = [eventManager.eventStore predicateForEventsWithStartDate:start
                                                                                        endDate:end
                                                                                      calendars:calendars];
    NSArray<EKEvent *> *events = [eventManager.eventStore eventsMatchingPredicate:fetchCalendarEvents];
    
    NSMutableDictionary<NSDate *, NSMutableArray<EKEvent *> *> *mutableDateEvents = [NSMutableDictionary dictionary];
    for (EKEvent *event in events) {
        // Reduce event start date to date components (year, month, day)
        NSDate *dateRepresentingThisDay = [[NSCalendar currentCalendar] startOfDayForDate:event.startDate];
        
        // If we don't yet have an array to hold the events for this day, create one
        NSMutableArray *eventsOnThisDay = [mutableDateEvents objectForKey:dateRepresentingThisDay];
        if (eventsOnThisDay == nil) {
            eventsOnThisDay = [NSMutableArray array];
            
            // Use the reduced date as dictionary key to later retrieve the event list this day
            [mutableDateEvents setObject:eventsOnThisDay forKey:dateRepresentingThisDay];
        }
        
        // Add the event to the list for this day
        [eventsOnThisDay addObject:event];
    }
    self.dateEvents = (NSDictionary<NSDate *, NSArray<EKEvent *> *> *)mutableDateEvents;
    
    // Create a sorted list of days
    NSArray *unsortedDays = [self.dateEvents allKeys];
    self.sortedDays = [unsortedDays sortedArrayUsingSelector:@selector(compare:)];
    
    completion();
}

@end
