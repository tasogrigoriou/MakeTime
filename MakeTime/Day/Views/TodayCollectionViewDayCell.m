//
//  TodayCollectionViewDayCell.m
//  MakeTime
//
//  Created by Anastasios Grigoriou on 8/28/17.
//  Copyright © 2017 Grigoriou. All rights reserved.
//

#import "TodayCollectionViewDayCell.h"
#import "TodayViewController.h"
#import "TodayCollectionViewLayout.h"
#import "TodayCollectionReusableView.h"
#import "UIColor+RBExtras.h"
#import "Chameleon.h"
#import "QuartzCore/QuartzCore.h"
#import "TodayCollectionViewCell.h"
#import "WeekViewController.h"
#import "CalendarView.h"
#import "SWRevealViewController.h"
#import "EventManager.h"
#import "AppDelegate.h"
#import "AddEventViewController.h"
#import "EventComponents.h"

@interface TodayCollectionViewDayCell () <UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, TodayCollectionViewLayoutDelegate>

@property (assign, nonatomic) BOOL isAccessToEventStoreGranted;

@property (strong, nonatomic) NSCalendar *calendar;
@property (strong, nonatomic) NSDateFormatter *dateFormatter;

@property (strong, nonatomic) AppDelegate *appDelegate;
@property (strong, nonatomic) NSArray *customCalendars;
@property (strong, nonatomic) NSArray *customEvents;

@property (strong, nonatomic) NSArray *twoHourIntervalsInMinutesArray;
@property (assign, nonatomic) NSInteger numberOfEventCarryOvers;

@property (strong, nonatomic) NSArray *eventComponentsArray;
@property (strong, nonatomic) NSArray *convertedEventComponentsArray;
@property (strong, nonatomic) NSArray<NSDate *> *everyTwoHourDateArray;

@end

@implementation TodayCollectionViewDayCell


#pragma mark - View Lifecycle


- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        [self configureViewAndCollectionView];
    }
    
    return self;
}


#pragma mark - UICollectionViewDataSource


- (NSInteger)collectionView:(UICollectionView *)collectionView
     numberOfItemsInSection:(NSInteger)section {
    // Call init/load methods here and NOT in initWithFrame: to hold off on accessing self.selectedDate property (until TodayVC sets it in cellForRowAtIndexPath: method)
    [self initTwoHourIntervalArray];
    [self initEveryTwoHourDateArray];
    [self loadConvertedEventComponents];
    
    return [self.convertedEventComponentsArray count];
    
    //   __block NSUInteger items = 0;
    //   dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
    //      [self initTwoHourIntervalArray];
    //      [self initEveryTwoHourDateArray];
    //      [self loadConvertedEventComponents];
    //
    //      dispatch_async(dispatch_get_main_queue(), ^{
    //         items = [self.convertedEventComponentsArray count];
    //      });
    //   });
    //   return items;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView
                  cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    
    TodayCollectionViewCell *cell = (TodayCollectionViewCell *)[collectionView dequeueReusableCellWithReuseIdentifier:@"TodayCell" forIndexPath:indexPath];
    EventComponents *eventComponent = self.convertedEventComponentsArray[indexPath.item];
    
    //   cell.eventLabel.text = eventComponent.title;
    cell.eventLabel.text = @"";
    cell.backgroundColor = [UIColor colorWithCGColor:eventComponent.calendar.CGColor];
    cell.contentView.backgroundColor = [UIColor clearColor];
    
    return cell;
}

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView
           viewForSupplementaryElementOfKind:(NSString *)kind
                                 atIndexPath:(NSIndexPath *)indexPath {
    TodayCollectionReusableView *view = [collectionView dequeueReusableSupplementaryViewOfKind:kind withReuseIdentifier:@"TodayCollectionReusableView" forIndexPath:indexPath];
    view.backgroundColor = [UIColor clearColor];
    
    // We want to start the cell hour at the hour user is waking up,
    // so we need to set dateBySettingHour based on when user sets their wake up time.
    NSDate *startOfDay = [self.calendar dateBySettingHour:0 minute:0 second:0 ofDate:[NSDate date] options:0];
    NSDate *dateOneHourAhead = [startOfDay dateByAddingTimeInterval:(long)indexPath.item * 3600];
    [self.dateFormatter setLocalizedDateFormatFromTemplate:@"h"];
    NSString *stringDate = [self.dateFormatter stringFromDate:dateOneHourAhead];
    view.hourLabel.text = stringDate;
    
    // Make sure the ReusableView is brought to the front of the subview hierarchy (on top of the cell)
    [self.collectionView bringSubviewToFront:view];
    
    // Disable user interaction to allow selection of the cell underneath the reusable view
    view.userInteractionEnabled = NO;
    
    return view;
}


#pragma mark - UICollectionViewDelegate


- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    EventComponents *eventComponent = self.convertedEventComponentsArray[indexPath.item];
    
    for (EKEvent *ekEvent in self.customEvents) {
        if ([ekEvent.eventIdentifier isEqualToString:eventComponent.identifier]) {
            NSLog(@"Found match: EKEvent = %@", ekEvent);
            [self.delegate dayCell:self didSelectEvent:ekEvent];
        }
    }
}


#pragma mark - TodayCollectionViewLayoutDelegate


- (NSRange)calendarViewLayout:(TodayCollectionViewLayout *)layout
   timespanForCellAtIndexPath:(NSIndexPath *)indexPath {
    EventComponents *eventComponent = self.convertedEventComponentsArray[indexPath.item];
    NSRange timespan = [self getTimespanForEventComponent:eventComponent];
    
    return timespan;
}

- (NSInteger)calendarViewLayout:(TodayCollectionViewLayout *)layout
     getStartingHourForTimespan:(NSRange)timespan {
    NSInteger startingHour = 0;
    for (NSNumber *twohourInMinutes in self.twoHourIntervalsInMinutesArray) {
        // Determine the event's starting hour by its location
        if (timespan.location >= [twohourInMinutes integerValue] &&
            timespan.location < [twohourInMinutes integerValue] + 120) {
            startingHour = [twohourInMinutes integerValue];
            break;
        }
    }
    
    return startingHour;
}

- (CGFloat)sizeForSupplementaryView {
    return [self.delegate sizeForSupplementaryView];
}


#pragma mark - EventComponents Methods


- (NSArray *)copyCustomEventsIntoEventComponents {
    NSMutableArray *eventComponentsArray = [NSMutableArray new];
    for (EKEvent *ekEvent in self.customEvents) {
        EventComponents *eventComponents = [EventComponents eventWithTitle:ekEvent.title
                                                                  calendar:ekEvent.calendar
                                                                 startDate:ekEvent.startDate
                                                                   endDate:ekEvent.endDate
                                                                     color:[UIColor colorWithCGColor:ekEvent.calendar.CGColor]
                                                                identifier:ekEvent.eventIdentifier];
        [eventComponentsArray addObject:eventComponents];
    }
    return (NSArray *)eventComponentsArray;
}

- (NSArray *)getConvertedEventComponents {
    NSMutableArray *convertedEventComponentsArray = [NSMutableArray new];
    
    for (EventComponents *eventComponent in self.eventComponentsArray) {
        
        for (NSDate *everyTwoHourDate in self.everyTwoHourDateArray) {
            if ([eventComponent.startDate compare:everyTwoHourDate] == NSOrderedDescending) {
                continue;
            }
            if ([eventComponent.endDate compare:everyTwoHourDate] == NSOrderedDescending) {
                EventComponents *newEventComponent = [EventComponents eventWithTitle:@""
                                                                            calendar:eventComponent.calendar
                                                                           startDate:everyTwoHourDate
                                                                             endDate:eventComponent.endDate
                                                                               color:eventComponent.color
                                                                          identifier:eventComponent.identifier];
                [convertedEventComponentsArray addObject:newEventComponent];
            }
        }
        
        [convertedEventComponentsArray addObject:eventComponent];
    }
    
    return (NSArray *)convertedEventComponentsArray;
}

- (NSRange)getTimespanForEventComponent:(EventComponents *)eventComponent {
    NSRange timespan;
    
    // Convert the event's startDate into the start of that specific day (0:00 Midnight)
    NSDate *startOfDay = [self.calendar dateBySettingHour:0 minute:0 second:0 ofDate:eventComponent.startDate options:0];
    
    // Get the start index of the event by calculating the minutes the start date is from the start of that day
    timespan.location = [self.calendar components:NSCalendarUnitMinute
                                         fromDate:startOfDay
                                           toDate:eventComponent.startDate
                                          options:0].minute;
    
    // Compute the length of the event by getting the number of minutes between the startDate and endDate
    timespan.length = [self.calendar components:NSCalendarUnitMinute
                                       fromDate:eventComponent.startDate
                                         toDate:eventComponent.endDate
                                        options:0].minute;
    return timespan;
}


#pragma mark - Private Methods


- (void)configureViewAndCollectionView {
    self.backgroundColor = [UIColor clearColor];
    
    TodayCollectionViewLayout *layout = [TodayCollectionViewLayout new];
    CGRect frame = self.frame;
    frame.origin = CGPointZero;
    self.collectionView = [[UICollectionView alloc] initWithFrame:frame collectionViewLayout:layout];
    self.collectionView.backgroundColor = [UIColor clearColor];
    self.collectionView.delegate = self;
    self.collectionView.dataSource = self;
    [self addSubview:self.collectionView];
    
    // Do NOT modify the content area of the scroll view using the safe area insets
    if (@available(iOS 11.0, *)) {
        self.collectionView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
    }
    
    [self.collectionView registerClass:[TodayCollectionViewCell class] forCellWithReuseIdentifier:@"TodayCell"];
    [self.collectionView registerClass:[TodayCollectionReusableView class] forSupplementaryViewOfKind:@"TodayCollectionReusableView" withReuseIdentifier:@"TodayCollectionReusableView"];
}

- (void)initTwoHourIntervalArray {
    NSInteger minutes = 0;
    NSMutableArray *twoHourIntervalsInMinutes = [NSMutableArray new];
    for (NSInteger i = 0; i <= 12; i++) {
        [twoHourIntervalsInMinutes addObject:@(minutes)];
        minutes += 120;
    }
    self.twoHourIntervalsInMinutesArray = (NSArray *)twoHourIntervalsInMinutes;
}

- (void)initEveryTwoHourDateArray {
    NSMutableArray *twoHourDateMutableArray = [NSMutableArray new];
    NSInteger hour = 0;
    
    for (NSInteger i = 0; i <= 12; i++) {
        NSDate *date = [self.calendar dateBySettingHour:0 minute:0 second:0 ofDate:self.selectedDate options:0];
        if (hour != 24) {
            date = [self.calendar dateBySettingHour:hour minute:0 second:0 ofDate:self.selectedDate options:0];
        } else {
            NSDateComponents *comps = [self.calendar components:NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay
                                                       fromDate:self.selectedDate];
            comps.day += 1;
            date = [self.calendar dateFromComponents:comps];
        }
        
        [twoHourDateMutableArray addObject:date];
        hour += 2;
    }
    
    self.everyTwoHourDateArray = (NSArray *)twoHourDateMutableArray;
}

- (void)loadConvertedEventComponents {
    if ([[NSUserDefaults standardUserDefaults] objectForKey:@"eventStoreGranted"]) {
        
        self.customCalendars = [self.appDelegate.eventManager loadCustomCalendars];
        self.customEvents = [self.appDelegate.eventManager getEventsOfAllCalendars:self.customCalendars
                                                                    thatFallOnDate:self.selectedDate];
        
        // Get converted event comps and sort them by startDate
        self.eventComponentsArray = [self copyCustomEventsIntoEventComponents];
        NSArray *convertedEventArray = [self getConvertedEventComponents];
        NSSortDescriptor *dateDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"startDate" ascending:YES];
        self.convertedEventComponentsArray = [convertedEventArray sortedArrayUsingDescriptors:@[dateDescriptor]];
        
        //      for (EKEvent *event in self.customEvents) {
        //         NSLog(@"custom event = %@", event);
        //      }
        //      for (EventComponents *eventComponent in self.convertedEventComponentsArray) {
        //         NSLog(@"eventComponent title = %@", eventComponent.title);
        //         NSLog(@"eventComponent startDate = %@", eventComponent.startDate);
        //         NSLog(@"eventComponent endDate = %@", eventComponent.endDate);
        //      }
    }
}


#pragma mark - Custom Getters


- (NSDateFormatter *)dateFormatter {
    if (!_dateFormatter) {
        _dateFormatter = [NSDateFormatter new];
        _dateFormatter.locale = [NSLocale currentLocale];
    }
    return _dateFormatter;
}

- (NSCalendar *)calendar {
    if (!_calendar) {
        _calendar = [NSCalendar currentCalendar];
    }
    return _calendar;
}

- (AppDelegate *)appDelegate {
    if (!_appDelegate) {
        _appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    }
    return _appDelegate;
}


@end

