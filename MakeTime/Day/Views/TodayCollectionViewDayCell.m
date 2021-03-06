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
#import "EventManager.h"
#import "AppDelegate.h"
#import "AddEventViewController.h"
#import "EventComponents.h"
#import "MakeTimeCache.h"
#import "TodayDayView.h"
#import "UIImage+Extras.h"
#import "UIView+Extras.h"

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

@property (strong, nonatomic) NSDate *date;
@property (strong, nonatomic) NSDate *startOfDay;

@end

@implementation TodayCollectionViewDayCell


#pragma mark - View Lifecycle


- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        [self configureViewAndCollectionView];
        [self hideCollectionView];
    }
    return self;
}

- (void)didSetSelectedDateWithFrame:(CGRect)frame {
    [self addTodayDayImageSubview:frame];
    [self loadEventData];
}

- (void)hideCollectionView {
    if ([[[NSUserDefaults standardUserDefaults] objectForKey:@"loadedDayCellCount"] integerValue] == 1) {
        [self.collectionView setHidden:YES duration:0.0 completion:nil];
    }
}

- (void)showCollectionView {
    if ([[[NSUserDefaults standardUserDefaults] objectForKey:@"loadedDayCellCount"] integerValue] == 2) {
        [self.collectionView setHidden:NO duration:0.3 completion:nil];
        [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithInteger:3] forKey:@"loadedDayCellCount"];
    } else if ([[[NSUserDefaults standardUserDefaults] objectForKey:@"loadedDayCellCount"] integerValue] == 3) {
        [self.collectionView setHidden:NO duration:0.0 completion:nil];
    }
}

- (void)addTodayDayImageSubview:(CGRect)frame {
    self.collectionView.frame = self.bounds;
    for (UIView *view in self.subviews) {
        if ([view isKindOfClass:[UIImageView class]]) {
            [view removeFromSuperview];
        }
    }
    MakeTimeCache *makeTimeCache = [MakeTimeCache sharedManager];
    TodayDayView *todayDayView = [[TodayDayView alloc] initWithFrame:frame];
    CGFloat size = [self.delegate sizeForSupplementaryView];
    todayDayView.backgroundColor = [UIColor clearColor];
    
//    if (makeTimeCache.todayDayImage == nil) {
        [todayDayView initHourLabelsWithCollectionView:self.collectionView sizeForView:size];
        makeTimeCache.todayDayImage = [UIImage imageWithView:todayDayView size:self.bounds.size];
//    }
    
    UIImageView *todayDayImageView = [[UIImageView alloc] initWithImage:makeTimeCache.todayDayImage];
    todayDayImageView.frame = self.bounds;
    todayDayImageView.backgroundColor = [UIColor clearColor];
    [self addSubview:todayDayImageView];
}

- (void)loadEventData {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        [self initEveryTwoHourDateArray];
        __weak TodayCollectionViewDayCell *weakSelf = self;
        [self loadConvertedEventComponents:^{
            dispatch_async(dispatch_get_main_queue(), ^{
                [weakSelf.collectionView reloadData];
                [weakSelf showCollectionView];
                if ([[[NSUserDefaults standardUserDefaults] objectForKey:@"loadedDayCellCount"] integerValue] == 1) {
                    [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithInteger:2] forKey:@"loadedDayCellCount"];
                }
            });
        }];
    });
}


#pragma mark - UICollectionViewDataSource


- (NSInteger)collectionView:(UICollectionView *)collectionView
     numberOfItemsInSection:(NSInteger)section {
    return [self.convertedEventComponentsArray count];
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView
                  cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    TodayCollectionViewCell *cell = (TodayCollectionViewCell *)[collectionView dequeueReusableCellWithReuseIdentifier:@"TodayCell" forIndexPath:indexPath];
    if (indexPath.item < self.convertedEventComponentsArray.count) {
        EventComponents *eventComponent = self.convertedEventComponentsArray[indexPath.item];
        
        cell.eventLabel.text = @"";
        cell.backgroundColor = [UIColor colorWithCGColor:eventComponent.calendar.CGColor];
    }
    
    return cell;
}


#pragma mark - UICollectionViewDelegate


- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.item < self.convertedEventComponentsArray.count) {
        EventComponents *eventComponent = self.convertedEventComponentsArray[indexPath.item];
        
        for (EKEvent *ekEvent in self.customEvents) {
            if ([ekEvent.eventIdentifier isEqualToString:eventComponent.identifier]) {
                NSLog(@"did select event with date = %@ --- %@", ekEvent.startDate, ekEvent.endDate);
                [self.delegate dayCell:self didSelectEvent:ekEvent];
            }
        }
    }
}


#pragma mark - TodayCollectionViewLayoutDelegate


- (NSRange)calendarViewLayout:(TodayCollectionViewLayout *)layout
   timespanForCellAtIndexPath:(NSIndexPath *)indexPath {
    NSLog(@"indexpath.item = %li", indexPath.item);
    if (indexPath.item < self.convertedEventComponentsArray.count) {
        EventComponents *eventComponent = self.convertedEventComponentsArray[indexPath.item];
        NSRange timespan = [self getTimespanForEventComponent:eventComponent];
        
        return timespan;
    }
    return NSMakeRange(0, 0);
}

- (NSInteger)calendarViewLayout:(TodayCollectionViewLayout *)layout
     getStartingHourForTimespan:(NSRange)timespan {
    NSInteger startingHour = 0;
    for (NSNumber *twohourInMinutes in [[MakeTimeCache sharedManager] twoHourIntervalsInMinutesArray]) {
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
        
        if ([self.calendar isDate:eventComponent.startDate inSameDayAsDate:self.selectedDate]) {
            [convertedEventComponentsArray addObject:eventComponent];
        }
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
    
    if ([[NSUserDefaults standardUserDefaults] objectForKey:@"isFirstTimeLoadingDayCell"]) {
        [self.collectionView setHidden:YES duration:0.0 completion:nil];
    }
}

- (void)initEveryTwoHourDateArray {
    NSMutableArray *twoHourDateMutableArray = [NSMutableArray new];
    NSInteger hour = 0;
    
    for (NSInteger i = 0; i < 12; i++) {
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

- (void)loadConvertedEventComponents:(void (^)(void))completion {
    if ([[NSUserDefaults standardUserDefaults] objectForKey:@"eventStoreGranted"]) {
        
        __weak TodayCollectionViewDayCell *weakSelf = self;
        [[EventManager sharedManager] loadCustomCalendarsWithCompletion:^(NSArray *calendars) {
            weakSelf.customCalendars = calendars;
            weakSelf.customEvents = [[EventManager sharedManager] getEventsOfAllCalendars:weakSelf.customCalendars
                                                                       thatFallOnDate:weakSelf.selectedDate];
            
            // Get converted event comps and sort them by startDate
            weakSelf.eventComponentsArray = [weakSelf copyCustomEventsIntoEventComponents];
            NSArray *convertedEventArray = [weakSelf getConvertedEventComponents];
            NSSortDescriptor *dateDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"startDate" ascending:YES];
            weakSelf.convertedEventComponentsArray = [convertedEventArray sortedArrayUsingDescriptors:@[dateDescriptor]];
            
            completion();
        }];
        
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
        [_dateFormatter setLocalizedDateFormatFromTemplate:@"h"];
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

- (NSDate *)date {
    if (!_date) {
        _date = [NSDate date];
    }
    return _date;
}

- (NSDate *)startOfDay {
    if (!_startOfDay) {
        _startOfDay = [self.calendar dateBySettingHour:0 minute:0 second:0 ofDate:self.date options:0];
    }
    return _startOfDay;
}


@end

