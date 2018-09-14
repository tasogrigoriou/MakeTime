//
//  WeekCollectionViewWeekCell.m
//  MakeTime
//
//  Created by Anastasios Grigoriou on 9/14/17.
//  Copyright © 2017 Grigoriou. All rights reserved.
//

#import "WeekCollectionViewWeekCell.h"
#import "AppDelegate.h"
#import "EventKit/EventKit.h"
#import "EventManager.h"
#import "WeekCollectionViewLayout.h"
#import "WeekCollectionViewCell.h"
#import "WeekCollectionReusableView.h"
#import "EventComponents.h"
#import "MakeTimeCache.h"
#import "WeekDayLineView.h"
#import "UIView+Extras.h"
#import "UIImage+Extras.h"

@interface WeekCollectionViewWeekCell () <UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, WeekCollectionViewLayoutDelegate>

@property (strong, nonatomic) NSCalendar *calendar;
@property (strong, nonatomic) NSDateFormatter *dateFormatter;

@property (strong, nonatomic) AppDelegate *appDelegate;
@property (strong, nonatomic) NSArray *customCalendars;
@property (strong, nonatomic) NSArray *customEvents;

@property (strong, nonatomic) NSArray *eventComponentsArray;
@property (strong, nonatomic) NSArray *convertedEventComponentsArray;

@property (strong, nonatomic) NSArray<NSDate *> *daysInWeek;

@property (strong, nonatomic) NSMutableArray<NSString *> *weekdayLabelsText;

@end


@implementation WeekCollectionViewWeekCell


#pragma mark - View Lifecycle


- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        [self configureViewAndCollectionView];
        [self hideCollectionView];
    }
    
    return self;
}

- (void)didSetSelectedDate {
    [self addWeekdayLineImageSubview];
    [self loadEventData];
}

- (void)hideCollectionView {
    if ([[[NSUserDefaults standardUserDefaults] objectForKey:@"loadedWeekCellCount"] integerValue] == 1) {
        [self.collectionView setHidden:YES duration:0.0 completion:nil];
    }
}

- (void)showCollectionView {
    if ([[[NSUserDefaults standardUserDefaults] objectForKey:@"loadedWeekCellCount"] integerValue] == 2) {
        [self.collectionView setHidden:NO duration:0.3 completion:nil];
        [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithInteger:3] forKey:@"loadedWeekCellCount"];
    } else if ([[[NSUserDefaults standardUserDefaults] objectForKey:@"loadedWeekCellCount"] integerValue] == 3) {
        [self.collectionView setHidden:NO duration:0.0 completion:nil];
    }
}

- (void)addWeekdayLineImageSubview {
    for (UIView *view in self.subviews) {
        if ([view isKindOfClass:[UIImageView class]]) {
            [view removeFromSuperview];
        }
    }
    MakeTimeCache *makeTimeCache = [MakeTimeCache sharedManager];
    WeekDayLineView *weekDayLineView = [[WeekDayLineView alloc] initWithFrame:self.collectionView.frame];
    weekDayLineView.backgroundColor = [UIColor clearColor];
    
    if (makeTimeCache.weekDayLineImage == nil) {
        [weekDayLineView initWeekdayLinesWithCollectionView:self.collectionView];
        makeTimeCache.weekDayLineImage = [UIImage imageWithView:weekDayLineView size:self.bounds.size];
    }
    
    UIImageView *weekDayLineImageView = [[UIImageView alloc] initWithImage:makeTimeCache.weekDayLineImage];
    weekDayLineImageView.frame = self.bounds;
    weekDayLineImageView.backgroundColor = [UIColor clearColor];
    [self addSubview:weekDayLineImageView];
}

- (void)loadEventData {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        [self initDaysInWeek];
        [self loadCustomCalendarsAndEvents];
        [self loadWeekdayLabelsArray];
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.collectionView reloadData];
            [self showCollectionView];
            if ([[[NSUserDefaults standardUserDefaults] objectForKey:@"loadedWeekCellCount"] integerValue] == 1) {
                [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithInteger:2] forKey:@"loadedWeekCellCount"];
            }
        });
    });
}

- (void)loadWeekdayLabelsArray {
    [self.weekdayLabelsText removeAllObjects];
    
    NSDateComponents *comps = [NSDateComponents new];
    NSDate *startOfWeek = [self startOfWeekOfDate:self.selectedDate];
    
    [self.dateFormatter setLocalizedDateFormatFromTemplate:@"E MMM d"];
    
    for (NSInteger i = 0; i < 7; i++) {
        comps.day = i;
        NSDate *weekDate = [self.calendar dateByAddingComponents:comps toDate:startOfWeek options:0];
        NSString *stringDate = [self.dateFormatter stringFromDate:weekDate];
        
        NSArray *foo = [stringDate componentsSeparatedByString:@" "];
        NSString *firstBit = [[foo objectAtIndex:0] componentsSeparatedByString:@","].firstObject;
        NSString *secondBit = [foo objectAtIndex:1];
        NSString *thirdBit = [foo objectAtIndex:2];
        //        NSString *whole = [NSString stringWithFormat:@"%@\n%@ %@", firstBit, secondBit, thirdBit];
        NSString *whole = [NSString stringWithFormat:@"%@\n%@", firstBit, thirdBit];
        [self.weekdayLabelsText addObject:whole];
    }
}


#pragma mark - UICollectionViewDataSource


- (NSInteger)collectionView:(UICollectionView *)collectionView
     numberOfItemsInSection:(NSInteger)section {
    return [self.convertedEventComponentsArray count];
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView
                  cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    WeekCollectionViewCell *cell = (WeekCollectionViewCell *)[collectionView dequeueReusableCellWithReuseIdentifier:@"WeekCollectionViewCell" forIndexPath:indexPath];
    EventComponents *eventComponent = self.convertedEventComponentsArray[indexPath.item];
    
    cell.calLabel.text = @"";
    cell.backgroundColor = [UIColor colorWithCGColor:eventComponent.calendar.CGColor];
    
    return cell;
}

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView
           viewForSupplementaryElementOfKind:(NSString *)kind
                                 atIndexPath:(NSIndexPath *)indexPath {
    WeekCollectionReusableView *view = [collectionView dequeueReusableSupplementaryViewOfKind:kind withReuseIdentifier:@"WeekCollectionReusableView" forIndexPath:indexPath];
    view.backgroundColor = [UIColor clearColor];
    
    if (self.weekdayLabelsText.count == 7) {
        view.weekdayLabel.text = self.weekdayLabelsText[indexPath.item];
    }
    
    return view;
}


#pragma mark - UICollectionViewDelegate


- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    EventComponents *eventComponent = self.convertedEventComponentsArray[indexPath.item];
    for (EKEvent *ekEvent in self.customEvents) {
        if ([ekEvent.eventIdentifier isEqualToString:eventComponent.identifier]) {
            [self.delegate weekCell:self didSelectEvent:ekEvent];
            break;
        }
    }
}

- (void)collectionView:(UICollectionView *)collectionView didHighlightItemAtIndexPath:(NSIndexPath *)indexPath {
    WeekCollectionViewCell *cell = (WeekCollectionViewCell *)[collectionView cellForItemAtIndexPath:indexPath];
    cell.backgroundColor = [UIColor clearColor];
    
    EventComponents *eventComponent = self.convertedEventComponentsArray[indexPath.item];
    cell.backgroundColor = [UIColor colorWithCGColor:eventComponent.calendar.CGColor];
}


#pragma mark - WeekCollectionViewLayoutDelegate


- (NSRange)weekViewLayout:(WeekCollectionViewLayout *)layout
timespanForCellAtIndexPath:(NSIndexPath *)indexPath {
    EventComponents *eventComponent = self.convertedEventComponentsArray[indexPath.item];
    return [self getTimespanForEvent:eventComponent];
}

- (NSUInteger)weekViewLayout:(WeekCollectionViewLayout *)layout
   weekdayForCellAtIndexPath:(NSIndexPath *)indexPath {
    EventComponents *eventComponent = self.convertedEventComponentsArray[indexPath.item];
    return [self getWeekdayForEvent:eventComponent];
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
    NSMutableArray *convertedEventComponentsArray = [NSMutableArray array];
    
    for (EventComponents *eventComponent in self.eventComponentsArray) {
        
        for (NSDate *day in self.daysInWeek) {
            if ([eventComponent.startDate compare:day] == NSOrderedDescending) {
                continue;
            }
            if ([eventComponent.endDate compare:day] == NSOrderedDescending) {
                EventComponents *newEventComponent = [EventComponents eventWithTitle:@""
                                                                            calendar:eventComponent.calendar
                                                                           startDate:day
                                                                             endDate:eventComponent.endDate
                                                                               color:eventComponent.color
                                                                          identifier:eventComponent.identifier];
                [convertedEventComponentsArray addObject:newEventComponent];
            }
        }
        
        NSDateComponents *eventWeekComponents = [self.calendar components:NSCalendarUnitWeekOfYear fromDate:eventComponent.startDate];
        NSDateComponents *selectedWeekComponents = [self.calendar components:NSCalendarUnitWeekOfYear fromDate:self.selectedDate];
        if (eventWeekComponents.weekOfYear == selectedWeekComponents.weekOfYear) {
            [convertedEventComponentsArray addObject:eventComponent];
        }
    }
    
    return (NSArray *)convertedEventComponentsArray;
}


#pragma mark - Private Methods


- (void)configureViewAndCollectionView {
    self.backgroundColor = [UIColor clearColor];
    
    WeekCollectionViewLayout *layout = [WeekCollectionViewLayout new];
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
    
    [self.collectionView registerClass:[WeekCollectionViewCell class] forCellWithReuseIdentifier:@"WeekCollectionViewCell"];
    [self.collectionView registerClass:[WeekCollectionReusableView class] forSupplementaryViewOfKind:@"WeekCollectionReusableView" withReuseIdentifier:@"WeekCollectionReusableView"];
    
    if ([[NSUserDefaults standardUserDefaults] objectForKey:@"isFirstTimeLoadingWeekCell"]) {
        [self.collectionView setHidden:YES duration:0.0 completion:nil];
    }
}

- (void)loadCustomCalendarsAndEvents {
    if ([[NSUserDefaults standardUserDefaults] objectForKey:@"eventStoreGranted"]) {
        
        __weak WeekCollectionViewWeekCell *weakSelf = self;
        [[EventManager sharedManager] loadCustomCalendarsWithCompletion:^(NSArray *calendars) {
            weakSelf.customCalendars = calendars;
        }];
        
        self.customEvents = [[EventManager sharedManager] getEventsOfAllCalendars:self.customCalendars
                                                                   thatFallInWeek:self.selectedDate];
        
        // Get converted event comps and sort them by startDate
        self.eventComponentsArray = [self copyCustomEventsIntoEventComponents];
        NSArray *convertedEventArray = [self getConvertedEventComponents];
        NSSortDescriptor *dateDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"startDate" ascending:YES];
        self.convertedEventComponentsArray = [convertedEventArray sortedArrayUsingDescriptors:@[dateDescriptor]];
        
        
        /*** LOGGING ***/
        for (EKEvent *event in self.customEvents) {
            NSLog(@"custom event date = %@ --- %@", event.startDate, event.endDate);
        }
        
        for (EventComponents *eventComponent in self.convertedEventComponentsArray) {
            NSLog(@"custom eventCOMPONENT date = %@ --- %@", eventComponent.startDate, eventComponent.endDate);
        }
        
        NSLog(@"self.customEvents count = %li", self.customEvents.count);
        
        //      for (EventComponents *eventComponent in self.convertedEventComponentsArray) {
        //         NSLog(@"eventComponent title = %@", eventComponent.title);
        //         NSLog(@"eventComponent startDate = %@", eventComponent.startDate);
        //         NSLog(@"eventComponent endDate = %@", eventComponent.endDate);
        //      }
    }
}

- (NSRange)getTimespanForEvent:(EventComponents *)eventComponent {
    NSRange timespan;
    
    NSDate *startOfDay = [self.calendar dateBySettingHour:0 minute:0 second:0 ofDate:eventComponent.startDate options:0];
    
    timespan.location = [self.calendar components:NSCalendarUnitMinute
                                         fromDate:startOfDay
                                           toDate:eventComponent.startDate
                                          options:0].minute;
    timespan.length = [self.calendar components:NSCalendarUnitMinute
                                       fromDate:eventComponent.startDate
                                         toDate:eventComponent.endDate
                                        options:0].minute;
    
    return timespan;
}

- (NSUInteger)getWeekdayForEvent:(EventComponents *)eventComponent {
    NSDateComponents *comps = [self.calendar components:NSCalendarUnitWeekday fromDate:eventComponent.startDate];
    return comps.weekday;
}

- (NSDate *)startOfWeekOfDate:(NSDate *)originalDate {
    NSCalendar *currentCal = [NSCalendar currentCalendar];
    [currentCal setFirstWeekday:1]; // Sun = 1, Mon = 2, etc.
    
    NSDateComponents *weekdayComponents = [currentCal components:NSCalendarUnitWeekday fromDate:originalDate];
    
    // Calculate the number of days to subtract and create NSDateComponents with them.
    NSDateComponents *componentsToSubtract = [[NSDateComponents alloc] init];
    NSInteger daysToSubtract = (([weekdayComponents weekday] - [currentCal firstWeekday]) + 7) % 7;
    [componentsToSubtract setDay:-1 * daysToSubtract];
    
    return [currentCal dateByAddingComponents:componentsToSubtract toDate:originalDate options:0];
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

- (NSMutableArray<NSString *> *)weekdayLabelsText {
    if (!_weekdayLabelsText) {
        _weekdayLabelsText = [NSMutableArray array];
    }
    return _weekdayLabelsText;
}

- (void)initDaysInWeek {
    // Get the first of the week (Sunday)
    NSDateComponents *firstOfTheWeekComponents = [self.calendar components:NSCalendarUnitYearForWeekOfYear | NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitWeekOfYear | NSCalendarUnitWeekday fromDate:self.selectedDate];
    [firstOfTheWeekComponents setWeekday:1];
    
    NSDate *firstOfTheWeekDate = [self.calendar dateFromComponents:firstOfTheWeekComponents];
    NSDate *startOfWeek = [self.calendar dateBySettingHour:0 minute:0 second:0 ofDate:firstOfTheWeekDate options:0];
    
    NSMutableArray *days = [NSMutableArray array];
    NSDateComponents *comps = [NSDateComponents new];
    for (NSInteger i = 0; i < 7; i++) {
        comps.day = i;
        NSDate *nextDay = [self.calendar dateByAddingComponents:comps toDate:startOfWeek options:0];
        [days addObject:nextDay];
    }
    
    _daysInWeek = (NSArray *)days;
}


@end
