//
//  MonthViewController.m
//  MakeTime
//
//  Created by Anastasios Grigoriou on 11/27/16.
//  Copyright © 2016 Grigoriou. All rights reserved.


#import "MonthViewController.h"
#import "TodayViewController.h"
#import "CalendarView.h"
#import "UIColor+RBExtras.h"
#import "Chameleon.h"
#import "CalendarViewDayCell.h"
#import <EventKit/EventKit.h>
#import "SWRevealViewController.h"


@interface MonthViewController () <CalendarViewDataSource, CalendarViewDelegate, UITextFieldDelegate>

@property (weak, nonatomic) IBOutlet UILabel *monthLabel;
@property (weak, nonatomic) IBOutlet UIButton *leftButton;
@property (weak, nonatomic) IBOutlet UIButton *rightButton;

@property (strong, nonatomic) CalendarView *calendarMonthView;

@property (strong, nonatomic) NSDateFormatter *headerFormatter;
@property (strong, nonatomic) NSCalendar *calendar;
@property (strong, nonatomic) NSArray *events;

@end


@implementation MonthViewController


#pragma mark - View Lifecycle


- (void)viewDidLoad
{
  [super viewDidLoad];
  
  [self configureViewAndCalendarView];
  [self giveGradientBackgroundColor];
}

- (void)viewDidAppear:(BOOL)animated
{
  [super viewDidAppear:animated];
  NSDate *today = [NSDate date];
  
  self.monthLabel.text = [self.headerFormatter stringFromDate:today];
  
  // Make the calendar appear in the month of today/set scope
  self.calendarMonthView.monthDisplayed = today;
  self.calendarMonthView.scope = CalendarScopeMonth;
}


#pragma mark - CalendarMonthViewDataSource


- (NSDate *)startDate
{
  NSDateComponents *offsetDateComps = [NSDateComponents new];
  offsetDateComps.year = -2;
  offsetDateComps.month = -3;
  NSDate *date = [self.calendar dateByAddingComponents:offsetDateComps toDate:[NSDate date] options:0];
  return date;
}

- (NSDate *)endDate
{
  NSDateComponents *offsetComponents = [NSDateComponents new];
  offsetComponents.year = 2;
  offsetComponents.month = 3;
  NSDate *date = [self.calendar dateByAddingComponents:offsetComponents toDate:[NSDate date] options:0];
  return date;
}


#pragma mark - CalendarMonthViewDelegate


- (void)calendarController:(CalendarView *)calendarViewController didSelectDay:(NSDate *)date
{
  SWRevealViewController *revealController = self.revealViewController;
  TodayViewController *todayVC = [TodayViewController new];
  NSDateComponents *comps = [NSDateComponents new];
  comps.day = 1;
  todayVC.selectedDate = [self.calendar dateByAddingComponents:comps toDate:date options:0];
  UINavigationController *newFrontVC = [[UINavigationController alloc] initWithRootViewController:todayVC];
  [revealController pushFrontViewController:newFrontVC animated:YES];
}

- (void)calendarController:(CalendarView *)calendarViewController didScrollToMonth:(NSDate *)date
{
  self.monthLabel.text = [self.headerFormatter stringFromDate:date];
}

- (void)calendarController:(CalendarView *)calendarViewController didScrollToWeek:(NSDate *)date
{
  
}

- (IBAction)leftButtonTouched:(id)sender
{
  [self updateMonthByValue:-1];
}

- (IBAction)rightButtonTouched:(id)sender
{
  [self updateMonthByValue:1];
}

- (void)updateMonthByValue:(NSInteger)value
{
  NSDateComponents *valueComponents = [NSDateComponents new];
  valueComponents.month = value;
  
  NSDate *updatedMonthDate = [self.calendar dateByAddingComponents:valueComponents
                                                            toDate:self.calendarMonthView.monthDisplayed
                                                           options:0];
  
  [self.calendarMonthView setMonthDisplayed:updatedMonthDate animated:YES];
}


#pragma mark - Private Methods


- (void)configureViewAndCalendarView
{
  self.view.backgroundColor = [UIColor clearColor];
  self.automaticallyAdjustsScrollViewInsets = NO;
  
  CGRect calendarFrame = CGRectMake(0, self.view.frame.origin.y + 65 + 24, self.view.frame.size.width - 280, 300);
  self.calendarMonthView = [[CalendarView alloc] initWithFrame:calendarFrame];
  self.calendarMonthView.backgroundColor = [UIColor clearColor];
  self.calendarMonthView.delegate = self;
  self.calendarMonthView.dataSource = self;
  self.calendarMonthView.showsEvents = YES;
  
  [self.view addSubview:self.calendarMonthView];
}

- (void)giveGradientBackgroundColor
{
  // Create an overlay view to give a gradient background color
  CGRect frame = CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height + 3000);
  UIView *overlayView = [[UIView alloc] initWithFrame:frame];
  UIColor *skyBlueLight = [UIColor colorWithHue:0.57 saturation:0.90 brightness:0.98 alpha:1.0];
  overlayView.backgroundColor = [UIColor colorWithGradientStyle:UIGradientStyleTopToBottom
                                                      withFrame:frame
                                                      andColors:@[[UIColor whiteColor], skyBlueLight]];
  [self.view insertSubview:overlayView atIndex:0];
}


#pragma mark - Custom Getters


- (NSCalendar *)calendar
{
  if (!_calendar) {
    _calendar = [NSCalendar currentCalendar];
  }
  return _calendar;
}
                          
- (NSDateFormatter *)headerFormatter
{
  if (!_headerFormatter) {
    _headerFormatter = [NSDateFormatter new];
    _headerFormatter.dateFormat = @"MMMM, yyyy";
  }
  return _headerFormatter;
}


@end

















