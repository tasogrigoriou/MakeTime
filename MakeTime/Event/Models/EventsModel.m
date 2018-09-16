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


- (void)loadEventsDataModelWithStartDate:(NSDate *)startDate
                                 endDate:(NSDate *)endDate
                               calendars:(NSArray<EKCalendar *> *)calendars
                              completion:(void (^)(void))completion {
    EventManager *eventManager = [EventManager sharedManager];
    NSDate *start = [[NSCalendar currentCalendar] startOfDayForDate:startDate];
    NSDate *end = [[NSCalendar currentCalendar] startOfDayForDate:endDate];
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
    

    [self mapDateToSectionIndex:self.dateEvents];
    
    completion();
}

- (void)mapDateToSectionIndex:(NSDictionary<NSDate *, NSArray<EKEvent *> *> *)dateEvents {
    NSMutableDictionary<NSDate *, NSNumber *> *indexedDates = [[NSMutableDictionary alloc] init];
    
    NSInteger index = 0;
    for (NSDate *day in self.sortedDays) {
        [indexedDates setObject:[NSNumber numberWithInteger:index] forKey:day];
        index += 1;
    }
    
    self.dateSections = (NSDictionary<NSDate *, NSNumber *> *)indexedDates;
}


@end
