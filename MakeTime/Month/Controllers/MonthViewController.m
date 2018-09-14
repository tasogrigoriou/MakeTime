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
#import "UIView+Extras.h"
#import "EventsModel.h"
#import "EventsTableViewCell.h"
#import "EditEventViewController.h"

@interface MonthViewController () <FSCalendarDelegate, FSCalendarDataSource, FSCalendarDelegateAppearance, UITextFieldDelegate, UITableViewDelegate, UITableViewDataSource>

@property (weak, nonatomic) IBOutlet UIButton *leftButton;
@property (weak, nonatomic) IBOutlet UIButton *rightButton;

@property (weak, nonatomic) IBOutlet FSCalendar *calendar;
@property (weak, nonatomic) IBOutlet UITableView *eventsTableView;

@property (strong, nonatomic) EventsModel *eventsModel;

@property (strong, nonatomic) NSDateFormatter *headerFormatter;
@property (strong, nonatomic) NSDateFormatter *tableViewHeaderFormatter;
@property (strong, nonatomic) NSDateFormatter *cellDateFormatter;

@property (strong, nonatomic) NSDictionary<NSDate *, NSArray<EKEvent *> *> *dateEvents;
@property (strong, nonatomic) NSArray<NSDate *> *daysInMonth;
@property (strong, nonatomic) NSArray *events;

@property (nonatomic) BOOL isFirstTimeLoadingData;

@end


@implementation MonthViewController


#pragma mark - View Lifecycle


- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self configureViewAndCalendarView];
    [self setTableViewContentInset];
    
    [self loadData];
    
    [self addTabBarNotificationObserver];
    [self addDataDidChangeNotificationObserver];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.navigationController.navigationBar.clipsToBounds = YES;
//    self.calendar.placeholderType = FSCalendarPlaceholderTypeNone;
}


#pragma mark - Loading Data


- (void)loadData {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        [self loadCalendarData];
    });
}

- (void)loadCalendarData {
    EventManager *eventManager = [EventManager sharedManager];
    __weak MonthViewController *weakSelf = self;
    [eventManager loadDateEventsInMonth:self.calendar.currentPage
                             completion:^(NSDictionary<NSDate *, NSArray<EKEvent *> *> *dateEvents, NSArray<NSDate *> *daysInMonth) {
                                 weakSelf.dateEvents = dateEvents;
                                 weakSelf.daysInMonth = daysInMonth;
                                 [weakSelf loadTableViewData];
                             }];
}

- (void)loadTableViewData {
    self.eventsModel = [[EventsModel alloc] initWithDateEvents:self.dateEvents daysInMonth:self.daysInMonth];
    __weak MonthViewController *weakSelf = self;
    [self.eventsModel loadEventsModelDataWithCompletion:^{
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakSelf refreshCalendarAndTableView];
        });
    }];
}

- (void)refreshCalendarAndTableView {
    if (self.isFirstTimeLoadingData) {
        [self.calendar setHidden:NO duration:0.3 completion:nil];
        self.isFirstTimeLoadingData = NO;
    }
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.35 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [UIView transitionWithView:self.calendar
                          duration:0.25
                           options:UIViewAnimationOptionTransitionCrossDissolve
                        animations:^{
                            [self.calendar reloadData];
                        }
                        completion:nil];
        
        [UIView transitionWithView:self.eventsTableView
                          duration:0.25
                           options:UIViewAnimationOptionTransitionCrossDissolve
                        animations:^{
                            [self.eventsTableView reloadData];
                            if ([self.eventsModel.dateEvents count] > 0) {
                                [self.eventsTableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]
                                                            atScrollPosition:UITableViewScrollPositionTop
                                                                    animated:YES];
                            }
                        }
                        completion:nil];
    });
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
        [calendar deselectDate:date];
        return;
    }
    if ([self.eventsModel.indexedEvents count] == 0) {
        return;
    }
    
    NSNumber *numIndex = self.eventsModel.indexedDates[date];
    if (numIndex != nil) {
        [self.eventsTableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:[numIndex integerValue]]
                                    atScrollPosition:UITableViewScrollPositionTop
                                            animated:YES];
    } else {
        NSDateComponents *comps = [NSDateComponents new];
        NSDate *nextDay = date;
        while (numIndex == nil && [nextDay compare:[self.daysInMonth lastObject]] == NSOrderedAscending) {
            comps.day += 1;
            nextDay = [[NSCalendar currentCalendar] dateByAddingComponents:comps toDate:date options:0];
            numIndex = self.eventsModel.indexedDates[nextDay];
        }
        
        if (numIndex != nil) {
            [self.eventsTableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:[numIndex integerValue]]
                                        atScrollPosition:UITableViewScrollPositionTop
                                                animated:YES];
        } else {
            // Scroll to last row of last section
            NSInteger rowIndex = [self.eventsModel.indexedEvents.lastObject indexOfObject:self.eventsModel.indexedEvents.lastObject.lastObject];
            NSInteger sectionIndex = [self.eventsModel.indexedDates count] - 1;
            [self.eventsTableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:rowIndex inSection:sectionIndex]
                                        atScrollPosition:UITableViewScrollPositionBottom
                                                animated:YES];
        }
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
    if (calendar.selectedDate != nil) {
        [calendar deselectDate:calendar.selectedDate];
    }
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
 */
- (NSInteger)calendar:(FSCalendar *)calendar numberOfEventsForDate:(NSDate *)date {
    return [self.dateEvents[date] count];
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


#pragma mark - UITableViewDataSource


- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return [self.eventsModel.dateEvents count];
}

- (NSInteger)tableView:(nonnull UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.eventsModel.indexedEvents[section] count];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return [self.tableViewHeaderFormatter stringFromDate:[self.eventsModel.indexedEvents[section] firstObject].startDate];
}

- (nonnull UITableViewCell *)tableView:(nonnull UITableView *)tableView cellForRowAtIndexPath:(nonnull NSIndexPath *)indexPath {
    EventsTableViewCell *cell = (EventsTableViewCell *)[tableView dequeueReusableCellWithIdentifier:@"EventsTableViewCell" forIndexPath:indexPath];
    
    EKEvent *event = [self.eventsModel.indexedEvents[indexPath.section] objectAtIndex:indexPath.row];
    
    cell.textLabel.text = event.calendar.title;
    cell.textLabel.textColor = [UIColor colorWithCGColor:event.calendar.CGColor];
    
    NSString *eventTitle = event.title.length != 0 ? event.title : @"No title";
    NSString *startDateTitle = [self.cellDateFormatter stringFromDate:event.startDate];
    NSString *endDateTitle = [self.cellDateFormatter stringFromDate:event.endDate];
    
    cell.detailTextLabel.text = [NSString stringWithFormat:@"%@  |  %@ - %@", eventTitle, startDateTitle, endDateTitle];
    
    return cell;
}


#pragma mark - UITableViewDelegate


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    EKEvent *event = [self.eventsModel.indexedEvents[indexPath.section] objectAtIndex:indexPath.row];
    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:[[EditEventViewController alloc] initWithEvent:event]];
    [self presentViewController:navController animated:YES completion:^{
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
    }];
}


#pragma mark - IBActions


- (IBAction)leftButtonTouched:(id)sender {
    [self updateMonthByValue:-1];
}

- (IBAction)rightButtonTouched:(id)sender {
    [self updateMonthByValue:1];
}

- (void)updateMonthByValue:(NSInteger)value {
    NSDateComponents *valueComponents = [NSDateComponents new];
    valueComponents.month = value;
    
    NSDate *updatedMonthDate = [[NSCalendar currentCalendar] dateByAddingComponents:valueComponents
                                                                             toDate:self.calendar.currentPage
                                                                            options:0];
    [self.calendar setCurrentPage:updatedMonthDate animated:YES];
}


#pragma mark - Private Methods


- (void)configureViewAndCalendarView {
    self.view.backgroundColor = [UIColor whiteColor];
    
    UINib *nib = [UINib nibWithNibName:@"EventsTableViewCell" bundle:nil];
    [self.eventsTableView registerNib:nib forCellReuseIdentifier:@"EventsTableViewCell"];
    
    self.calendar.appearance.titleFont = [UIFont fontWithName:@"AvenirNext-Medium" size:12.0f]; // day text font
    self.calendar.appearance.weekdayFont = [UIFont fontWithName:@"AvenirNext-Regular" size:14.0f]; // weekday text font
    self.calendar.appearance.headerTitleFont = [UIFont fontWithName:@"AvenirNextCondensed-Medium" size:17.0f]; // month text font
    
    [self.view bringSubviewToFront:self.leftButton];
    [self.view bringSubviewToFront:self.rightButton];
    
    [self.calendar setHidden:YES duration:0.0 completion:nil];
    self.isFirstTimeLoadingData = YES;
}

- (void)setTableViewContentInset {
    self.eventsTableView.contentInset = UIEdgeInsetsMake(-7, 0, 0, 0);
}

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

- (void)addTabBarNotificationObserver {
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(scrollToToday)
                                                 name:@"didSelectLastSelectedViewController"
                                               object:nil];
}

- (void)scrollToToday {
    [self.calendar setCurrentPage:[NSDate date] animated:YES];
}

- (void)addDataDidChangeNotificationObserver {
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(dataDidChange)
                                                 name:@"calendarOrEventDataDidChange"
                                               object:nil];
}

- (void)dataDidChange {
    [self loadData];
}


#pragma mark - Custom Getters


- (NSDateFormatter *)headerFormatter {
    if (!_headerFormatter) {
        _headerFormatter = [NSDateFormatter new];
        _headerFormatter.locale = [NSLocale currentLocale];
        _headerFormatter.dateFormat = @"MMMM, yyyy";
    }
    return _headerFormatter;
}

- (NSDateFormatter *)tableViewHeaderFormatter {
    if (!_tableViewHeaderFormatter) {
        _tableViewHeaderFormatter = [NSDateFormatter new];
        _tableViewHeaderFormatter.locale = [NSLocale currentLocale];
        _tableViewHeaderFormatter.dateFormat = @"E, MMMM d";
    }
    return _tableViewHeaderFormatter;
}

- (NSDateFormatter *)cellDateFormatter {
    if (!_cellDateFormatter) {
        _cellDateFormatter = [NSDateFormatter new];
        _cellDateFormatter.locale = [NSLocale currentLocale];
        _cellDateFormatter.dateFormat = @"h:mm a";
    }
    return _cellDateFormatter;
}


@end
