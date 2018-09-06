//
//  EventManager.h
//  MakeTime
//
//  Created by Anastasios Grigoriou on 5/30/17.
//  Copyright © 2017 Grigoriou. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "UIKit/UIKit.h"
#import <EventKit/EventKit.h>

@interface EventManager : NSObject

@property (strong, nonatomic) EKEventStore *eventStore;
@property (strong, nonatomic) NSDateFormatter *dateFormatter;

// Use this later to store all selected calendars in NSUserDefaults to be retrieved from previous app state
@property (strong, nonatomic) NSMutableArray *selectedCalendars;

@property (strong, nonatomic) NSArray *defaultCalendars;
@property (strong, nonatomic) NSArray *customCalendars;
@property (strong, nonatomic) NSMutableArray *customCalendarIdentifiers;

// Assigns the range (location, length) of the event within a particular day.
@property (assign, nonatomic) NSRange *timespanOfEvent;

+ (id)sharedManager;

- (void)saveCustomCalendarIdentifier:(NSString *)identifier;
- (void)removeCustomCalendarIdentifier:(NSString *)identifier;
- (BOOL)isCalendarCustomWithIdentifier:(NSString *)identifier;

- (NSArray *)loadCustomCalendars;
- (NSArray *)loadDefaultCalendars;

// Method that gets events of all custom calendars on a particular day
- (NSArray *)getEventsOfAllCalendars:(NSArray<EKCalendar *> *)calendars thatFallOnDate:(NSDate *)date;
- (NSArray *)getEventsOfAllCalendars:(NSArray<EKCalendar *> *)calendars thatFallInWeek:(NSDate *)date;

- (void)deleteEventWithIdentifier:(NSString *)identifier;

@end