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
#import "SWRevealViewController.h"
#import "FSCalendar.h"


@interface MonthViewController () <FSCalendarDelegate, FSCalendarDataSource, UITextFieldDelegate>

@property (weak, nonatomic) IBOutlet UIButton *leftButton;
@property (weak, nonatomic) IBOutlet UIButton *rightButton;
@property (weak, nonatomic) IBOutlet FSCalendar *calendar;

@property (strong, nonatomic) NSDateFormatter *headerFormatter;
@property (strong, nonatomic) NSArray *events;

@end


@implementation MonthViewController


#pragma mark - View Lifecycle


- (void)viewDidLoad {
    [super viewDidLoad];
    [self configureViewAndCalendarView];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.navigationController.navigationBar.clipsToBounds = YES;
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
    return nil;
}

/**
 * Asks the dataSource the maximum date to display.
 */
- (NSDate *)maximumDateForCalendar:(FSCalendar *)calendar {
    return nil;
}

/**
 * Asks the data source for a cell to insert in a particular data of the calendar.
 */
- (__kindof FSCalendarCell *)calendar:(FSCalendar *)calendar cellForDate:(NSDate *)date atMonthPosition:(FSCalendarMonthPosition)position {
    return nil;
}

/**
 * Asks the dataSource the number of event dots for a specific date.
 *
 *
 *   - (UIColor *)calendar:(FSCalendar *)calendar appearance:(FSCalendarAppearance *)appearance eventColorForDate:(NSDate *)date;
 *   - (NSArray *)calendar:(FSCalendar *)calendar appearance:(FSCalendarAppearance *)appearance eventColorsForDate:(NSDate *)date;
 */
- (NSInteger)calendar:(FSCalendar *)calendar numberOfEventsForDate:(NSDate *)date {
    return 0;
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


#pragma mark - Custom Getters


- (NSDateFormatter *)headerFormatter {
    if (!_headerFormatter) {
        _headerFormatter = [NSDateFormatter new];
        _headerFormatter.dateFormat = @"MMMM, yyyy";
    }
    return _headerFormatter;
}


@end
