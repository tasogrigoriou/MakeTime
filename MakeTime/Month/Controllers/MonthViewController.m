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
#import "UIColor+Converter.h"
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
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *calendarHeightConstraint;

@property (strong, nonatomic) EventsModel *eventsModel;

@property (strong, nonatomic) NSArray<EKCalendar *> *customCalendars;

@property (strong, nonatomic) NSDateFormatter *headerFormatter;
@property (strong, nonatomic) NSDateFormatter *tableViewHeaderFormatter;
@property (strong, nonatomic) NSDateFormatter *cellDateFormatter;

@property (nonatomic) BOOL isFirstTimeLoadingData;

@property (nonatomic) BOOL orientationChanged;

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
    [self addOrientationChangeObserver];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.navigationController.navigationBar.clipsToBounds = YES;
    if (self.orientationChanged) {
        self.isFirstTimeLoadingData = YES;
        [self.calendar setHidden:YES duration:0.0 completion:nil];
        [self loadData];
        self.orientationChanged = NO;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.01 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self.calendar reloadData];
            [self.view layoutIfNeeded];
            [self scrollToToday];
            [self.calendar setCurrentPage:[NSDate date]];
            [self.calendar selectDate:[NSDate date] scrollToDate:YES];
            [self.calendar deselectDate:[NSDate date]];
        });
    }
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    if (UIInterfaceOrientationIsLandscape([[UIApplication sharedApplication] statusBarOrientation])) {
        [self.calendar setScope:FSCalendarScopeWeek];
        [self scrollToToday];
    } else {
        [self.calendar setScope:FSCalendarScopeMonth];
        self.calendarHeightConstraint.constant = 300;
    }
}

- (void)viewWillTransitionToSize:(CGSize)size
       withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        if (UIInterfaceOrientationIsLandscape([[UIApplication sharedApplication] statusBarOrientation])) {
            [self.calendar setScope:FSCalendarScopeWeek];
            self.calendarHeightConstraint.constant = 120;
        } else {
            [self.calendar setScope:FSCalendarScopeMonth];
            self.calendarHeightConstraint.constant = 300;
        }
    });
    [[NSNotificationCenter defaultCenter] postNotificationName:@"orientationChanged" object:self userInfo:nil];
}


#pragma mark - Loading Data


- (void)loadData {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        [self loadCalendarData];
    });
}

- (void)loadCalendarData {
    EventManager *eventManager = [EventManager sharedManager];
    self.eventsModel = [[EventsModel alloc] init];
    
    NSDate *startDate = self.calendar.currentPage;
    NSDateComponents *comps = [NSDateComponents new];
    comps.month = 1;
    NSDate *endDate = [[NSCalendar currentCalendar] dateByAddingComponents:comps toDate:startDate options:0];
    
    __weak MonthViewController *weakSelf = self;
    [eventManager loadCustomCalendarsWithCompletion:^(NSArray<EKCalendar *> *calendars) {
        weakSelf.customCalendars = calendars;
    }];
    [self.eventsModel loadEventsDataModelWithStartDate:startDate endDate:endDate calendars:self.customCalendars completion:^{
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
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
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
                            NSDate *startOfToday = [[NSCalendar currentCalendar] startOfDayForDate:[NSDate date]];
                            NSNumber *sectionIndex = [self.eventsModel.dateSections objectForKey:startOfToday];
                            if (sectionIndex != nil && [self.eventsModel.dateEvents count] > 0) {
                                [self.eventsTableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0
                                                                                                inSection:[sectionIndex integerValue]]
                                                            atScrollPosition:UITableViewScrollPositionTop
                                                                    animated:YES];
                            } else if ([self.eventsModel.dateEvents count] > 0) {
                                [self.eventsTableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]
                                                            atScrollPosition:UITableViewScrollPositionTop
                                                                    animated:YES];
                            }
                        }
                        completion:^(BOOL success) {
                            if (UIInterfaceOrientationIsLandscape([[UIApplication sharedApplication] statusBarOrientation])) {
                                self.calendarHeightConstraint.constant = 120;
                            }
                        }];
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
    if ([self.eventsModel.dateEvents count] == 0) {
        return;
    }
    
    NSNumber *sectionIndex = [self.eventsModel.dateSections objectForKey:date];
    if (sectionIndex != nil) {
        [self.eventsTableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:[sectionIndex integerValue]]
                                    atScrollPosition:UITableViewScrollPositionTop
                                            animated:YES];
    } else {
        NSDateComponents *nextMonthComps = [NSDateComponents new];
        nextMonthComps.month = 1;
        NSDate *startOfNextMonth = [[NSCalendar currentCalendar] dateByAddingComponents:nextMonthComps
                                                                                 toDate:self.calendar.currentPage options:0];
        NSDateComponents *nextDayComps = [NSDateComponents new];
        NSDate *nextDay = date;
        
        while (sectionIndex == nil && ([nextDay compare:startOfNextMonth] != NSOrderedSame)) {
            nextDayComps.day += 1;
            nextDay = [[NSCalendar currentCalendar] dateByAddingComponents:nextDayComps toDate:date options:0];
            sectionIndex = [self.eventsModel.dateSections objectForKey:nextDay];
        }
        
        if (sectionIndex != nil) {
            [self.eventsTableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:[sectionIndex integerValue]]
                                        atScrollPosition:UITableViewScrollPositionTop
                                                animated:YES];
        } else {
            // Scroll to last row of last section
            NSDate *lastDayOfMonthWithEvents = [self.eventsModel.sortedDays lastObject];
            NSArray *eventsOnThisDay = [self.eventsModel.dateEvents objectForKey:lastDayOfMonthWithEvents];
            
            NSInteger rowIndex = [eventsOnThisDay indexOfObject:[eventsOnThisDay lastObject]];
            NSInteger sectionIndex = [self.eventsModel.sortedDays count] - 1;
            
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
    return [[self eventColorsForDate:date] count];
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

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSDate *dateRepresentingThisDay = [self.eventsModel.sortedDays objectAtIndex:section];
    NSArray *eventsOnThisDay = [self.eventsModel.dateEvents objectForKey:dateRepresentingThisDay];
    return [eventsOnThisDay count];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    NSDate *dateRepresentingThisDay = [self.eventsModel.sortedDays objectAtIndex:section];
    return [self.tableViewHeaderFormatter stringFromDate:dateRepresentingThisDay];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    EventsTableViewCell *cell = (EventsTableViewCell *)[tableView dequeueReusableCellWithIdentifier:@"EventsTableViewCell"
                                                                                       forIndexPath:indexPath];
    NSDate *dateRepresentingThisDay = [self.eventsModel.sortedDays objectAtIndex:indexPath.section];
    NSArray *eventsOnThisDay = [self.eventsModel.dateEvents objectForKey:dateRepresentingThisDay];
    EKEvent *event = [eventsOnThisDay objectAtIndex:indexPath.row];
    
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
    NSDate *dateRepresentingThisDay = [self.eventsModel.sortedDays objectAtIndex:indexPath.section];
    NSArray *eventsOnThisDay = [self.eventsModel.dateEvents objectForKey:dateRepresentingThisDay];
    EKEvent *event = [eventsOnThisDay objectAtIndex:indexPath.row];
    
    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:[[EditEventViewController alloc] initWithEvent:event]];
    [self presentViewController:navController animated:YES completion:^{
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
    }];
}

#pragma mark - IBActions


- (IBAction)leftButtonTouched:(id)sender {
    if (self.calendar.scope == FSCalendarScopeMonth) {
        [self updateMonthByValue:-1];
    } else {
        [self updateWeekByValue:-1];
    }
}

- (IBAction)rightButtonTouched:(id)sender {
    if (self.calendar.scope == FSCalendarScopeMonth) {
        [self updateMonthByValue:1];
    } else {
        [self updateWeekByValue:1];
    }
}

- (void)updateMonthByValue:(NSInteger)value {
    NSDateComponents *valueComponents = [NSDateComponents new];
    valueComponents.month = value;
    
    NSDate *updatedMonthDate = [[NSCalendar currentCalendar] dateByAddingComponents:valueComponents
                                                                             toDate:self.calendar.currentPage
                                                                            options:0];
    [self.calendar setCurrentPage:updatedMonthDate animated:YES];
}

- (void)updateWeekByValue:(NSInteger)value {
    NSDateComponents *valueComponents = [NSDateComponents new];
    valueComponents.weekOfYear = value;
    
    NSDate *updatedMonthDate = [[NSCalendar currentCalendar] dateByAddingComponents:valueComponents
                                                                             toDate:self.calendar.currentPage
                                                                            options:0];
    [self.calendar setCurrentPage:updatedMonthDate animated:YES];
}


#pragma mark - Private Methods


- (void)configureViewAndCalendarView {
    self.view.backgroundColor = [UIColor whiteColor];
    
    [self.eventsTableView registerNib:[UINib nibWithNibName:@"EventsTableViewCell" bundle:nil] forCellReuseIdentifier:@"EventsTableViewCell"];
    
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
    NSMutableSet *eventColors = [NSMutableSet set];
    for (EKEvent *event in self.eventsModel.dateEvents[date]) {
        UIColor *calendarColor = [UIColor colorWithCGColor:event.calendar.CGColor];
        [eventColors addObject:calendarColor];
    }
    return [eventColors count] > 0 ? [eventColors allObjects] : nil;
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

- (void)addOrientationChangeObserver {
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(orientationDidChange)
                                                 name:@"orientationChanged"
                                               object:nil];
}

- (void)dataDidChange {
    [self loadData];
}

- (void)orientationDidChange {
    self.orientationChanged = YES;
    self.isFirstTimeLoadingData = YES;
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
