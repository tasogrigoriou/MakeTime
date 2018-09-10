//
//  MonthViewController.m
//  MakeTime
//
//  Created by Anastasios Grigoriou on 11/27/16.
//  Copyright © 2016 Grigoriou. All rights reserved.


#import "MonthViewController.h"
#import "TodayViewController.h"
#import "UIColor+RBExtras.h"
#import "Chameleon.h"
#import "CalendarViewDayCell.h"
#import <EventKit/EventKit.h>
#import "FSCalendar.h"
#import "AppDelegate.h"


@interface MonthViewController () <FSCalendarDelegate, FSCalendarDataSource, FSCalendarDelegateAppearance, UITextFieldDelegate>

@property (weak, nonatomic) IBOutlet UIButton *leftButton;
@property (weak, nonatomic) IBOutlet UIButton *rightButton;
@property (weak, nonatomic) IBOutlet FSCalendar *calendar;

@property (strong, nonatomic) AppDelegate *appDelegate;
@property (strong, nonatomic) NSDateFormatter *headerFormatter;

@property (strong, nonatomic) NSMutableDictionary<NSDate *, NSArray<EKEvent *> *> *dateEvents;
@property (strong, nonatomic) NSArray *events;


@end


@implementation MonthViewController


#pragma mark - View Lifecycle


- (void)viewDidLoad {
    [super viewDidLoad];
    [self configureViewAndCalendarView];
    [self loadData];
    [self addTabBarNotificationObserver];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.navigationController.navigationBar.clipsToBounds = YES;
//    self.calendar.placeholderType = FSCalendarPlaceholderTypeNone;
}

- (void)loadData {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        [self loadCalendarData];
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.calendar reloadData];
        });
    });
}

- (void)loadCalendarData {
    [self.dateEvents removeAllObjects];
    EventManager *eventManager = [EventManager sharedManager];
    for (NSDate *day in [self getDaysInCurrentMonth]) {
        NSArray<EKEvent *> *eventsOnDay = [eventManager getEventsOfAllCalendars:eventManager.customCalendars
                                                                 thatFallOnDate:day];
        self.dateEvents[day] = eventsOnDay;
    }
}

- (NSArray<NSDate *> *)getDaysInCurrentMonth {
    NSMutableArray *result = [NSMutableArray array];
    NSCalendar *calendar = [NSCalendar currentCalendar];
    
    NSDate *startDate = self.calendar.currentPage;
    
    NSDateComponents *endComps = [NSDateComponents new];
    endComps.month = 1;
    NSDate *endDate = [calendar dateByAddingComponents:endComps toDate:self.calendar.currentPage options:0];
    
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


#pragma mark - FSCalendarDelegate


/**
 Asks the delegate whether the specific date is allowed to be selected by tapping.
 */
- (BOOL)calendar:(FSCalendar *)calendar shouldSelectDate:(NSDate *)date atMonthPosition:(FSCalendarMonthPosition)monthPosition {
    return YES;
}

/**
 Tells the delegate a date in the calendar is selected by tapping.
 */
- (void)calendar:(FSCalendar *)calendar didSelectDate:(NSDate *)date atMonthPosition:(FSCalendarMonthPosition)monthPosition {
    if (monthPosition == FSCalendarMonthPositionPrevious || monthPosition == FSCalendarMonthPositionNext) {
        [calendar setCurrentPage:date animated:YES];
    }
}

/**
 Asks the delegate whether the specific date is allowed to be deselected by tapping.
 */
- (BOOL)calendar:(FSCalendar *)calendar shouldDeselectDate:(NSDate *)date atMonthPosition:(FSCalendarMonthPosition)monthPosition {
    return YES;
}

/**
 Tells the delegate a date in the calendar is deselected by tapping.
 */
- (void)calendar:(FSCalendar *)calendar didDeselectDate:(NSDate *)date atMonthPosition:(FSCalendarMonthPosition)monthPosition {
    
}


/**
 Tells the delegate the calendar is about to change the bounding rect.
 */
- (void)calendar:(FSCalendar *)calendar boundingRectWillChange:(CGRect)bounds animated:(BOOL)animated {
    
}

/**
 Tells the delegate that the specified cell is about to be displayed in the calendar.
 */
- (void)calendar:(FSCalendar *)calendar willDisplayCell:(FSCalendarCell *)cell forDate:(NSDate *)date atMonthPosition:(FSCalendarMonthPosition)monthPosition {
    
}

/**
 Tells the delegate the calendar is about to change the current page.
 */
- (void)calendarCurrentPageDidChange:(FSCalendar *)calendar {
    [self loadData];
}


#pragma mark - FSCalendarDataSource


/**
 * Asks the dataSource for a title for the specific date as a replacement of the day text
 */
- (nullable NSString *)calendar:(FSCalendar *)calendar titleForDate:(NSDate *)date {
    return nil;
}

/**
 * Asks the dataSource for a subtitle for the specific date under the day text.
 */
- (nullable NSString *)calendar:(FSCalendar *)calendar subtitleForDate:(NSDate *)date {
    return nil;
}

/**
 * Asks the dataSource for an image for the specific date.
 */
- (nullable UIImage *)calendar:(FSCalendar *)calendar imageForDate:(NSDate *)date {
    return nil;
}

/**
 * Asks the dataSource the minimum date to display.
 */
- (NSDate *)minimumDateForCalendar:(FSCalendar *)calendar {
    return calendar.minimumDate;
}

/**
 * Asks the dataSource the maximum date to display.
 */
- (NSDate *)maximumDateForCalendar:(FSCalendar *)calendar {
    return calendar.maximumDate;
}

/**
 * Asks the data source for a cell to insert in a particular data of the calendar.
 */
//- (__kindof FSCalendarCell *)calendar:(FSCalendar *)calendar cellForDate:(NSDate *)date atMonthPosition:(FSCalendarMonthPosition)position {
//    return nil;
//}

/**
 * Asks the dataSource the number of event dots for a specific date.
 *
 *
 *   - (UIColor *)calendar:(FSCalendar *)calendar appearance:(FSCalendarAppearance *)appearance eventColorForDate:(NSDate *)date;
 *   - (NSArray *)calendar:(FSCalendar *)calendar appearance:(FSCalendarAppearance *)appearance eventColorsForDate:(NSDate *)date;
 */
- (NSInteger)calendar:(FSCalendar *)calendar numberOfEventsForDate:(NSDate *)date {
    return self.dateEvents[date].count;
}


#pragma mark - FSCalendarDelegateAppearance


/**
 * Asks the delegate for a fill color in unselected state for the specific date.
 */
- (nullable UIColor *)calendar:(FSCalendar *)calendar appearance:(FSCalendarAppearance *)appearance fillDefaultColorForDate:(NSDate *)date {
    return nil;
}

/**
 * Asks the delegate for a fill color in selected state for the specific date.
 */
- (nullable UIColor *)calendar:(FSCalendar *)calendar appearance:(FSCalendarAppearance *)appearance fillSelectionColorForDate:(NSDate *)date {
    return nil;
}

/**
 * Asks the delegate for day text color in unselected state for the specific date.
 */
- (nullable UIColor *)calendar:(FSCalendar *)calendar appearance:(FSCalendarAppearance *)appearance titleDefaultColorForDate:(NSDate *)date {
    return nil;
}

/**
 * Asks the delegate for day text color in selected state for the specific date.
 */
- (nullable UIColor *)calendar:(FSCalendar *)calendar appearance:(FSCalendarAppearance *)appearance titleSelectionColorForDate:(NSDate *)date {
    return nil;
}

/**
 * Asks the delegate for subtitle text color in unselected state for the specific date.
 */
- (nullable UIColor *)calendar:(FSCalendar *)calendar appearance:(FSCalendarAppearance *)appearance subtitleDefaultColorForDate:(NSDate *)date {
    return nil;
}

/**
 * Asks the delegate for subtitle text color in selected state for the specific date.
 */
- (nullable UIColor *)calendar:(FSCalendar *)calendar appearance:(FSCalendarAppearance *)appearance subtitleSelectionColorForDate:(NSDate *)date {
    return nil;
}

/**
 * Asks the delegate for event colors for the specific date.
 */
- (nullable NSArray<UIColor *> *)calendar:(FSCalendar *)calendar appearance:(FSCalendarAppearance *)appearance
                eventDefaultColorsForDate:(NSDate *)date {
    return [self eventColorsForDate:date];
}

/**
 * Asks the delegate for multiple event colors in selected state for the specific date.
 */
- (nullable NSArray<UIColor *> *)calendar:(FSCalendar *)calendar appearance:(FSCalendarAppearance *)appearance
              eventSelectionColorsForDate:(NSDate *)date {
    return [self eventColorsForDate:date];
}

/**
 * Asks the delegate for a border color in unselected state for the specific date.
 */
- (nullable UIColor *)calendar:(FSCalendar *)calendar appearance:(FSCalendarAppearance *)appearance borderDefaultColorForDate:(NSDate *)date {
    return nil;
}

/**
 * Asks the delegate for a border color in selected state for the specific date.
 */
- (nullable UIColor *)calendar:(FSCalendar *)calendar appearance:(FSCalendarAppearance *)appearance borderSelectionColorForDate:(NSDate *)date {
    return nil;
}

/**
 * Asks the delegate for an offset for day text for the specific date.
 */
- (CGPoint)calendar:(FSCalendar *)calendar appearance:(FSCalendarAppearance *)appearance titleOffsetForDate:(NSDate *)date {
    return CGPointZero;
}

/**
 * Asks the delegate for an offset for subtitle for the specific date.
 */
- (CGPoint)calendar:(FSCalendar *)calendar appearance:(FSCalendarAppearance *)appearance subtitleOffsetForDate:(NSDate *)date {
    return CGPointZero;
}

/**
 * Asks the delegate for an offset for image for the specific date.
 */
- (CGPoint)calendar:(FSCalendar *)calendar appearance:(FSCalendarAppearance *)appearance imageOffsetForDate:(NSDate *)date {
    return CGPointZero;
}

/**
 * Asks the delegate for an offset for event dots for the specific date.
 */
- (CGPoint)calendar:(FSCalendar *)calendar appearance:(FSCalendarAppearance *)appearance eventOffsetForDate:(NSDate *)date {
    return CGPointZero;
}


/**
 * Asks the delegate for a border radius for the specific date.
 */
//- (CGFloat)calendar:(FSCalendar *)calendar appearance:(FSCalendarAppearance *)appearance borderRadiusForDate:(NSDate *)date {
//    return 0;
//}

- (nullable NSArray<UIColor *> *)eventColorsForDate:(NSDate *)date {
    NSMutableArray *eventColors = [NSMutableArray array];
    for (EKEvent *event in self.dateEvents[date]) {
        UIColor *calendarColor = [UIColor colorWithCGColor:event.calendar.CGColor];
        if (![eventColors containsObject:calendarColor]) {
            [eventColors addObject:calendarColor];
        }
    }
    return [eventColors count] > 0 ? eventColors : nil;
}


#pragma mark - IBActions


- (IBAction)leftButtonTouched:(id)sender {
    [self updateMonthByValue:-1];
}

- (IBAction)rightButtonTouched:(id)sender {
    [self updateMonthByValue:1];
}

- (void)updateMonthByValue:(NSInteger)value {
    NSCalendar *currentCalendar = [NSCalendar currentCalendar];
    NSDateComponents *valueComponents = [NSDateComponents new];
    valueComponents.month = value;
    
    NSDate *updatedMonthDate = [currentCalendar dateByAddingComponents:valueComponents
                                                                toDate:self.calendar.currentPage
                                                               options:0];
    [self.calendar setCurrentPage:updatedMonthDate animated:YES];
}


#pragma mark - Private Methods


- (void)configureViewAndCalendarView {
    self.view.backgroundColor = [UIColor whiteColor];
    self.automaticallyAdjustsScrollViewInsets = NO;
    
    self.calendar.appearance.titleFont = [UIFont fontWithName:@"AvenirNext-Medium" size:12.0f];
    self.calendar.appearance.weekdayFont = [UIFont fontWithName:@"AvenirNextCondensed-Regular" size:15.0f];
    self.calendar.appearance.headerTitleFont = [UIFont fontWithName:@"AvenirNextCondensed-Medium" size:17.0f];
    
    [self.view bringSubviewToFront:self.leftButton];
    [self.view bringSubviewToFront:self.rightButton];
}

- (void)addTabBarNotificationObserver {
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(scrollToToday)
                                                 name:@"didSelectLastSelectedViewController"
                                               object:nil];
}

- (void)scrollToToday {
    [self.calendar setCurrentPage:[NSDate date] animated:YES];
}


#pragma mark - Custom Getters


- (NSDateFormatter *)headerFormatter {
    if (!_headerFormatter) {
        _headerFormatter = [NSDateFormatter new];
        _headerFormatter.dateFormat = @"MMMM, yyyy";
    }
    return _headerFormatter;
}

- (AppDelegate *)appDelegate {
    if (!_appDelegate) {
        _appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    }
    return _appDelegate;
}

- (NSMutableDictionary<NSDate *, NSArray<EKEvent *> *> *)dateEvents {
    if (!_dateEvents) {
        _dateEvents = [[NSMutableDictionary alloc] init];
    }
    return _dateEvents;
}


@end
