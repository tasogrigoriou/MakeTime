//
//  EventManager.m
//  MakeTime
//
//  Created by Anastasios Grigoriou on 5/30/17.
//  Copyright © 2017 Grigoriou. All rights reserved.
//

#import "EventManager.h"
#import "UIColor+RBExtras.h"
#import "TodayCollectionViewLayout.h"

@interface EventManager ()

@property (strong, nonatomic) NSCalendar *calendar;

@property (strong, nonatomic) NSMutableArray *calendarChecker;
@property (assign, nonatomic) BOOL isNotFirstLaunch;

@end

@implementation EventManager


#pragma mark - Initialization


+ (id)sharedManager {
    static EventManager *sharedMyManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedMyManager = [[self alloc] init];
    });
    return sharedMyManager;
}

- (instancetype)init {
    if (self = [super init]) {
        self.eventStore = [EKEventStore new];
        NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
        
        // Load the custom calendar identifiers
        self.customCalendarIdentifiers = [[userDefaults objectForKey:@"customCalendarIdentifiers"] mutableCopy];
        
        [self setupCalendarColors];
    }
    
    return self;
}


#pragma mark - Custom Accessors


- (void)saveCustomCalendarIdentifier:(NSString *)identifier {
    [self.customCalendarIdentifiers addObject:identifier];
    [[NSUserDefaults standardUserDefaults] setObject:self.customCalendarIdentifiers forKey:@"customCalendarIdentifiers"];
}

- (void)removeCustomCalendarIdentifier:(NSString *)identifier {
    [self.customCalendarIdentifiers removeObject:identifier];
    [[NSUserDefaults standardUserDefaults] setObject:self.customCalendarIdentifiers forKey:@"customCalendarIdentifiers"];
}

- (EKEventStore *)eventStore {
    if (!_eventStore) {
        _eventStore = [EKEventStore new];
    }
    return _eventStore;
}

- (NSCalendar *)calendar {
    if (!_calendar) {
        _calendar = [NSCalendar currentCalendar];
    }
    return _calendar;
}

- (NSDateFormatter *)dateFormatter {
    if (!_dateFormatter) {
        _dateFormatter = [NSDateFormatter new];
        _dateFormatter.locale = [NSLocale autoupdatingCurrentLocale];
    }
    return _dateFormatter;
}

- (NSMutableArray *)customCalendarIdentifiers {
    if (!_customCalendarIdentifiers) {
        _customCalendarIdentifiers = [NSMutableArray new];
    }
    return _customCalendarIdentifiers;
}

- (BOOL)isNotFirstLaunch {
    if (!_isNotFirstLaunch) {
        NSNumber *firstLaunch = @(_isNotFirstLaunch);
        [[NSUserDefaults standardUserDefaults] setObject:firstLaunch forKey:@"isNotFirstLaunch"];
    }
    return _isNotFirstLaunch;
}


#pragma mark - Private Methods


- (BOOL)isCalendarCustomWithIdentifier:(NSString *)identifier {
    BOOL isCustomCalendar = NO;
    for (NSString *customCalendarIdentifier in self.customCalendarIdentifiers) {
        if ([identifier isEqualToString:customCalendarIdentifier]) {
            isCustomCalendar = YES;
            break;
        }
    }
    return isCustomCalendar;
}

- (void)loadCustomCalendarsWithCompletion:(void (^)(NSArray<EKCalendar *> *))completion {
    NSMutableArray *customCals = [NSMutableArray new];
    
    // Load default calendars (if we're on first launch of app)
    BOOL isNotFirstLaunch = [[NSUserDefaults standardUserDefaults] objectForKey:@"isNotFirstLaunch"];
    if (!isNotFirstLaunch) {
        NSArray *defaultCals = [self loadDefaultCalendars];
        for (EKCalendar *cal in defaultCals) {
            if (![[NSUserDefaults standardUserDefaults] objectForKey:cal.calendarIdentifier]) {
                [customCals addObject:cal];
            }
        }
        // Otherwise, just load the cal ID's present in NSUserDefaults and use them to load the EKCalendars
    } else {
        NSArray *userDefaultCalIdentifiers = [[NSUserDefaults standardUserDefaults] objectForKey:@"customCalendarIdentifiers"];
        NSArray *eventStoreCals = [self.eventStore calendarsForEntityType:EKEntityTypeEvent];
        
        for (NSString *calIdentifier in userDefaultCalIdentifiers) {
            for (EKCalendar *currentCal in eventStoreCals) {
                if ([currentCal.calendarIdentifier isEqualToString:calIdentifier]) {
                    [customCals addObject:currentCal];
                }
            }
        }
    }
    
    /**** Log NSUserDefaults to view calendar identifiers ****/
    //     NSLog(@"NSUserDefaults: \n%@", [[NSUserDefaults standardUserDefaults] dictionaryRepresentation]);
    
    self.customCalendars = (NSArray<EKCalendar *> *)customCals;
    completion(self.customCalendars);
}

- (NSArray *)loadDefaultCalendars {
    // When creating a new calendar, two values must be set: The title and the source of the calendar.
    // The source is actually the type of the calendar, and in our case it’s the Local source.
    NSMutableArray *calendarArray = [NSMutableArray new];
    NSError *error;
    
    // Init default calendars (if we are first launch of app)
    self.isNotFirstLaunch = YES;
    NSNumber *firstLaunch = @(self.isNotFirstLaunch);
    [[NSUserDefaults standardUserDefaults] setObject:firstLaunch forKey:@"isNotFirstLaunch"];
    
    // Family - Hot Pink default color
    EKCalendar *familyCalendar = [EKCalendar calendarForEntityType:EKEntityTypeEvent eventStore:self.eventStore];
    familyCalendar.title = @"Family";
    familyCalendar.CGColor = [UIColor colorWithRed:(238/255.0) green:(106/255.0) blue:(167/255.0) alpha:1.0].CGColor;
    [calendarArray addObject:familyCalendar];
    
    // Work - Turquoise default color
    EKCalendar *workCalendar = [EKCalendar calendarForEntityType:EKEntityTypeEvent eventStore:self.eventStore];
    workCalendar.title = @"Work";
    workCalendar.CGColor = [UIColor colorWithRed:(64/255.0) green:(224/255.0) blue:(208/255.0) alpha:1.0].CGColor;
    [calendarArray addObject:workCalendar];
    
    // School - Dark Orchid default color
    EKCalendar *schoolCalendar = [EKCalendar calendarForEntityType:EKEntityTypeEvent eventStore:self.eventStore];
    schoolCalendar.title = @"School";
    schoolCalendar.CGColor = [UIColor colorWithRed:(154/255.0) green:(50/255.0) blue:(205/255.0) alpha:1.0].CGColor;
    [calendarArray addObject:schoolCalendar];
    
    // Exercise - Dark Orange default color
    EKCalendar *exerciseCalendar = [EKCalendar calendarForEntityType:EKEntityTypeEvent eventStore:self.eventStore];
    exerciseCalendar.title = @"Exercise";
    exerciseCalendar.CGColor = [UIColor colorWithRed:(255/255.0) green:(140/255.0) blue:(0/255.0) alpha:1.0].CGColor;
    [calendarArray addObject:exerciseCalendar];
    
    // Social - Green default color
    EKCalendar *socialCalendar = [EKCalendar calendarForEntityType:EKEntityTypeEvent eventStore:self.eventStore];
    socialCalendar.title = @"Social";
    socialCalendar.CGColor = [UIColor colorWithRed:(118/255.0) green:(238/255.0) blue:(0/255.0) alpha:1.0].CGColor;
    [calendarArray addObject:socialCalendar];
    
    // Cleaning - Yellow default color
    EKCalendar *cleaningCalendar = [EKCalendar calendarForEntityType:EKEntityTypeEvent eventStore:self.eventStore];
    cleaningCalendar.title = @"Cleaning";
    cleaningCalendar.CGColor = [UIColor colorWithRed:(238/255.0) green:(238/255.0) blue:(0/255.0) alpha:1.0].CGColor;
    [calendarArray addObject:cleaningCalendar];
    
    for (EKCalendar *cal in calendarArray) {
        cal.source = self.eventStore.defaultCalendarForNewEvents.source;
        
        NSMutableArray *calendarIdentifiers = [[[NSUserDefaults standardUserDefaults] objectForKey:@"customCalendarIdentifiers"] mutableCopy];
        if ([calendarIdentifiers containsObject:cal.calendarIdentifier]) {
            [self.calendarChecker addObject:@(YES)];
            NSLog(@"calendar %@ is contained in User Defaults", cal.title);
        }
        
        // If cal identifier is not found in NSUserDefaults, save the calendar to the event store.
        if (![self.calendarChecker containsObject:@(YES)]) {
            if (![self.eventStore saveCalendar:cal commit:YES error:&error]) {
                NSLog(@"%@", [error localizedDescription]);
            } else {
                NSLog(@"Successfully saved calendar - %@", cal.title);
                [self saveCustomCalendarIdentifier:cal.calendarIdentifier];
            }
        }
    }
    
    self.defaultCalendars = (NSArray *)calendarArray;
    return self.defaultCalendars;
}

// Get all events that fall on a given date
- (NSArray *)getEventsOfAllCalendars:(NSArray<EKCalendar *> *)calendars
                      thatFallOnDate:(NSDate *)date {
    NSDate *startOfDay = [self.calendar dateBySettingHour:0 minute:0 second:0 ofDate:date options:0];
    NSDateComponents *components = [NSDateComponents new];
    components.day = 1;
    NSDate *endOfDay = [self.calendar dateByAddingComponents:components toDate:startOfDay options:0];
    
    NSPredicate *predicate = [self.eventStore predicateForEventsWithStartDate:startOfDay
                                                                      endDate:endOfDay
                                                                    calendars:calendars];
    
    NSArray *eventsArray = [self.eventStore eventsMatchingPredicate:predicate];
    
    // Copy all objects one by one to a new mutable array, and make sure that the same event is not added twice.
    BOOL eventExists = NO;
    NSMutableArray *uniqueEventsArray = [NSMutableArray new];
    for (EKEvent *event in eventsArray) {
        if (event.recurrenceRules && event.recurrenceRules.count > 0) {
            for (EKEvent *uniqueEvent in uniqueEventsArray) {
                if ([uniqueEvent.eventIdentifier isEqualToString:event.eventIdentifier]) {
                    eventExists = YES;
                    break;
                }
            }
        }
        if (!eventExists) {
            [uniqueEventsArray addObject:event];
        }
    }
    
    // sort uniqueEventsArray by start date and return array
    return [uniqueEventsArray sortedArrayUsingSelector:@selector(compareStartDateWithEvent:)];
}

- (NSArray *)getEventsOfAllCalendars:(NSArray<EKCalendar *> *)calendars
                      thatFallInWeek:(NSDate *)date {
    // Get the first of the week (Sunday)
    NSDateComponents *firstOfTheWeekComponents = [self.calendar components:NSCalendarUnitYearForWeekOfYear | NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitWeekOfYear | NSCalendarUnitWeekday
                                                                  fromDate:date];
    [firstOfTheWeekComponents setWeekday:1];
    
    NSDate *firstOfTheWeekDate = [self.calendar dateFromComponents:firstOfTheWeekComponents];
    NSDate *startOfWeek = [self.calendar dateBySettingHour:0 minute:0 second:0 ofDate:firstOfTheWeekDate options:0];
    
    NSDateComponents *components = [NSDateComponents new];
    components.weekOfYear = 1;
    NSDate *endOfWeek = [self.calendar dateByAddingComponents:components toDate:startOfWeek options:0];
    
    NSPredicate *predicate = [self.eventStore predicateForEventsWithStartDate:startOfWeek
                                                                      endDate:endOfWeek
                                                                    calendars:calendars];
    
    NSArray *eventsArray = [self.eventStore eventsMatchingPredicate:predicate];
    
    // sort eventsArray by start date and return array
    return [eventsArray sortedArrayUsingSelector:@selector(compareStartDateWithEvent:)];
}

- (void)deleteEventWithIdentifier:(NSString *)identifier {
    EKEvent *event = [self.eventStore eventWithIdentifier:identifier];
    NSError *error;
    if (![self.eventStore removeEvent:event span:EKSpanFutureEvents error:&error]) {
        NSLog(@"%@", [error localizedDescription]);
    }
}

- (void)loadDateEventsInMonth:(NSDate *)month
                   completion:(void (^)(NSDictionary<NSDate *, NSArray<EKEvent *> *> *dateEvents, NSArray<NSDate *> *daysInMonth))completion {
    NSMutableDictionary<NSDate *, NSArray<EKEvent *> *> *mutableDateEvents = [[NSMutableDictionary alloc] init];
    NSArray<NSDate *> *daysInMonth = [self getDaysInMonth:month];
    for (NSDate *day in daysInMonth) {
        NSArray<EKEvent *> *eventsOnDay = [self getEventsOfAllCalendars:self.customCalendars
                                                         thatFallOnDate:day];
        if ([eventsOnDay count] > 0) {
            mutableDateEvents[day] = eventsOnDay;
        }
    }
    
    self.dateEvents = (NSDictionary<NSDate *, NSArray<EKEvent *> *> *)mutableDateEvents;
    completion(self.dateEvents, daysInMonth);
}

- (void)loadDateEventsFromStartDate:(NSDate *)startDate
                            endDate:(NSDate *)endDate
                           calendar:(EKCalendar *)calendar
                         completion:(void (^)(NSDictionary<NSDate *, NSArray<EKEvent *> *> *dateEvents, NSArray<NSDate *> *days))completion {
    NSMutableDictionary<NSDate *, NSArray<EKEvent *> *> *mutableDateEvents = [[NSMutableDictionary alloc] init];
    NSArray<NSDate *> *days = [self getDaysFromStartDate:startDate endDate:endDate];
    for (NSDate *day in days) {
        NSArray<EKEvent *> *eventsOnDay = [self getEventsOfAllCalendars:@[calendar]
                                                         thatFallOnDate:day];
        if ([eventsOnDay count] > 0) {
            mutableDateEvents[day] = eventsOnDay;
        }
    }
    
    self.dateEvents = (NSDictionary<NSDate *, NSArray<EKEvent *> *> *)mutableDateEvents;
    completion(self.dateEvents, days);
}

- (NSArray<NSDate *> *)getDaysInMonth:(NSDate *)month {
    NSMutableArray *result = [NSMutableArray array];
    NSCalendar *calendar = [NSCalendar currentCalendar];
    
    NSDate *startDate = month;
    
    NSDateComponents *endComps = [NSDateComponents new];
    endComps.month = 1;
    NSDate *endDate = [calendar dateByAddingComponents:endComps toDate:month options:0];
    
    NSDateComponents *comps = [calendar components:NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay
                                          fromDate:startDate];
    NSDate *date = [calendar dateFromComponents:comps];
    
    while (![date isEqualToDate:endDate]) {
        [result addObject:date];
        comps.day += 1;
        date = [calendar dateFromComponents:comps];
    }
    
    return (NSArray *)result;
}

- (NSArray<NSDate *> *)getDaysFromStartDate:(NSDate *)startDate endDate:(NSDate *)endDate {
    NSMutableArray<NSDate *> *result = [NSMutableArray array];
    NSCalendar *calendar = [NSCalendar currentCalendar];
    
    NSDateComponents *comps = [calendar components:NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay
                                          fromDate:startDate];
    NSDate *date = [calendar dateFromComponents:comps];
    
    while (![date isEqualToDate:endDate]) {
        [result addObject:date];
        comps.day += 1;
        date = [calendar dateFromComponents:comps];
    }
    
    return (NSArray<NSDate *> *)result;
}

- (void)setupCalendarColors {
    NSMutableDictionary<UIColor *, NSString *> *colorStrings = [NSMutableDictionary dictionary];
    
    UIColor *hotPink = [UIColor colorWithRed:(238/255.0) green:(106/255.0) blue:(167/255.0) alpha:1.0];
    UIColor *turquoise = [UIColor colorWithRed:(64/255.0) green:(224/255.0) blue:(208/255.0) alpha:1.0];
    UIColor *darkOrchid = [UIColor colorWithRed:(154/255.0) green:(50/255.0) blue:(205/255.0) alpha:1.0];
    UIColor *darkOrange = [UIColor colorWithRed:(255/255.0) green:(140/255.0) blue:(0/255.0) alpha:1.0];
    UIColor *green = [UIColor colorWithRed:(118/255.0) green:(238/255.0) blue:(0/255.0) alpha:1.0];
    UIColor *yellow = [UIColor colorWithRed:(238/255.0) green:(238/255.0) blue:(0/255.0) alpha:1.0];
    
    colorStrings[hotPink] = @"Pink";
    colorStrings[turquoise] = @"Turquoise";
    colorStrings[darkOrchid] = @"Orchid";
    colorStrings[darkOrange] = @"Orange";
    colorStrings[green] = @"Green";
    colorStrings[yellow] = @"Yellow";
    
    self.calendarUIColors = @[hotPink, turquoise, darkOrchid, darkOrange, green, yellow];
    self.calendarStringColors = @[@"Pink", @"Turquoise", @"Orchid", @"Orange", @"Green", @"Yellow"];
    self.colorStrings = (NSDictionary<UIColor *, NSString *> *)colorStrings;
}


@end














