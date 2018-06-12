//
//  CalendarView.h
//  MakeTime
//
//  Created by Anastasios Grigoriou on 2/4/17.
//  Copyright © 2017 Grigoriou. All rights reserved.
//

#import <UIKit/UIKit.h>

// Follows the line of thinking of a native UICollectionView,
// where the view is responsible for rendering the data taken from another object that conforms to two protocols,
// one for data provision, and the other for interactivity.
@protocol CalendarViewDataSource;
@protocol CalendarViewDelegate;

// Define an NS_ENUM to handle both our month and week views
typedef NS_ENUM(NSUInteger, CalendarScope) {
    CalendarScopeMonth,
    CalendarScopeWeek
};


@interface CalendarView : UIView

@property (strong, nonatomic) NSDate *dateSelected;
@property (strong, nonatomic) NSDate *monthDisplayed; // a date representing the first of the month we want displayed.
@property (strong, nonatomic) NSDate *weekDisplayed; // represents first day of the week of the displayed WeekCell

// Declare the scope of the calendar.
// (Assign will generate a setter which assigns the value to the instance variable directly, rather than copying or retaining it. This is best for primitive types like NSInteger and CGFloat, or objects you don't directly own, such as delegates)
@property (assign, nonatomic) CalendarScope scope;

@property (assign, nonatomic) BOOL showsEvents; // EKEventStore

@property (weak, nonatomic) id<CalendarViewDelegate> delegate;
@property (weak, nonatomic) id<CalendarViewDataSource> dataSource;

- (void)setDateSelected:(NSDate *)dateSelected animated:(BOOL)animated;
- (void)setMonthDisplayed:(NSDate *)monthDisplayed animated:(BOOL)animated;
- (void)setWeekDisplayed:(NSDate *)weekDisplayed animated:(BOOL)animated;

@end


@protocol CalendarViewDataSource <NSObject>

@required

- (NSDate *)startDate;

@optional

- (NSDate *)endDate;

@end


@protocol CalendarViewDelegate <NSObject>

@optional

- (void)calendarController:(CalendarView *)calendarViewController didSelectDay:(NSDate *)date;
- (void)calendarController:(CalendarView *)calendarViewController didScrollToMonth:(NSDate *)date;
- (void)calendarController:(CalendarView *)calendarViewController didScrollToWeek:(NSDate *)date;
// Default is YES.
- (BOOL)calendarController:(CalendarView *)calendarViewController canSelectDate:(NSDate *)date;

@end



