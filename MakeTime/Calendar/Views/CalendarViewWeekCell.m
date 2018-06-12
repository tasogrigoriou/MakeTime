//
//  CalendarViewWeekCell.m
//  MakeTime
//
//  Created by Anastasios Grigoriou on 3/1/17.
//  Copyright © 2017 Grigoriou. All rights reserved.


#import "CalendarViewWeekCell.h"
#import "CalendarViewDayCell.h"
#import "CollectionViewFlowLayout.h"
#import "CalendarHeaderView.h"


@interface CalendarViewWeekCell () <UICollectionViewDelegate, UICollectionViewDataSource>

@property (nonatomic, assign) NSInteger firstWeekdayOfMonthIndex;
@property (nonatomic, assign) NSInteger lastWeekOfMonthIndex;
@property (nonatomic, assign) NSInteger lastWeekdayOfMonthIndex;

@property (nonatomic, assign) NSInteger weekOfYearIndex;
@property (nonatomic, assign) NSInteger weekOfMonthIndex;

@property (nonatomic, assign) NSInteger numberOfDaysInMonth;

@property (nonatomic, strong) NSDateComponents *weekComponents;
@property (nonatomic, assign) NSInteger numberOfWeeks;

@property (nonatomic, strong) NSDateComponents *todayDateComponents;

@property (nonatomic, strong) NSCalendar *calendar;

@end


@implementation CalendarViewWeekCell


- (instancetype)initWithFrame:(CGRect)frame
{
  self = [super initWithFrame:frame];
  
  if (self) {
    
    CollectionViewFlowLayout *weekFlowLayout = [[CollectionViewFlowLayout alloc]
                                                initWithCollectionViewSize:frame.size
                                                headerHeight:[CalendarHeaderView height]
                                                scope:CalendarScopeWeek];
    
    self.collectionView = [[UICollectionView alloc]
                           initWithFrame:CGRectMake(0.0f, 0.0f, frame.size.width, frame.size.height)
                           collectionViewLayout:weekFlowLayout];
    self.collectionView.backgroundColor = [UIColor clearColor];
    
    // Assign the delegate/data source to be parent controller.
    self.collectionView.delegate = self;
    self.collectionView.dataSource = self;
    
    [self addSubview:self.collectionView];
    
    // Register our custom classes.
    [self.collectionView registerClass:[CalendarViewDayCell class]
            forCellWithReuseIdentifier:NSStringFromClass([CalendarViewDayCell class])];
    
    [self.collectionView registerClass:[CalendarHeaderView class]
            forSupplementaryViewOfKind:UICollectionElementKindSectionHeader
                   withReuseIdentifier:NSStringFromClass([CalendarHeaderView class])];
  }
  
  return self;
}


#pragma mark - UICollectionViewDataSource


- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
  return 1;
}


// Return 7 cells for each day in the week.
- (NSInteger)collectionView:(UICollectionView *)collectionView
     numberOfItemsInSection:(NSInteger)section
{
  if (!self.displayWeekDate) {
    return 0;
  }
  
  return 7;
}


- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView
           viewForSupplementaryElementOfKind:(NSString *)kind
                                 atIndexPath:(NSIndexPath *)indexPath
{
  UICollectionReusableView *reusableView = nil;
  
  if (kind == UICollectionElementKindSectionHeader) {
    
    CalendarHeaderView *headerView = (CalendarHeaderView *)
    [collectionView dequeueReusableSupplementaryViewOfKind:UICollectionElementKindSectionHeader
                                       withReuseIdentifier:NSStringFromClass([CalendarHeaderView class])
                                              forIndexPath:indexPath];
    
    reusableView = headerView;
    
  }
  
  return reusableView;
}


- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
  CalendarViewDayCell *dayCell = (CalendarViewDayCell *)[collectionView dequeueReusableCellWithReuseIdentifier:NSStringFromClass([CalendarViewDayCell class]) forIndexPath:indexPath];
  
  // Use NSDateComponents to draw out each cell item for each day in the month,
  // plus the offsetted days at beginning and end of each month.
  NSDateComponents *offsetComponents = [[NSDateComponents alloc] init];
  
  // Start at 0 to begin with our calculations below...
  offsetComponents.day = 0;
  
  // Make room for the days of the previous month.
  // (ex. If the first day of the month is a Tue then we need 2 slots)
  offsetComponents.day -= _firstWeekdayOfMonthIndex;
  
  // Add the day offset corresponding to the cell about to be drawn (will increment up by 1 for each cell item).
  offsetComponents.day += indexPath.item;
  
  // Get the date for each day cell corresponding to the offsetComponents.
  NSDate *dayCellDate = [_calendar dateByAddingComponents:offsetComponents
                                                   toDate:_displayWeekDate
                                                  options:0];
  
  // Create components from our dayCellDate to display in our dayCell label.
  NSDateComponents *dayDateComponents = [_calendar
                                         components:NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay
                                         fromDate:dayCellDate];
  
  // Give each dayCell label text which displays the day from our dayDateComponents as a number.
  dayCell.label.text = [NSString stringWithFormat:@"%li", (long)dayDateComponents.day];
  
  //    NSLog(@"dayCell label text = %@", dayCell.label.text);
  
  // Assign the dayCell's date property to our NSDate.
  dayCell.date = dayCellDate;
  
  dayCell.isToday = (dayDateComponents.day == _todayDateComponents.day && dayDateComponents.month == _todayDateComponents.month && dayDateComponents.year == _todayDateComponents.year);
  
  // Set default day selected boolean to NO.
  dayCell.isDaySelected = NO;
  
  if (self.dateSelected) {
    NSLog(@"dateSelected = %@", self.dateSelected);
    
    NSDateComponents *selectedDateComponents = [_calendar
                                                components:NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay | NSCalendarUnitWeekOfYear
                                                fromDate:self.dateSelected];
    
    // Set isDaySelected to yes if the selected date is in the current year, month and day.
    if (dayDateComponents.year == selectedDateComponents.year && dayDateComponents.month == selectedDateComponents.month && dayDateComponents.day == selectedDateComponents.day) {
      dayCell.isDaySelected = YES;
    }
    
  }
  
  
  // if we are at the first week of the month, check if the firstWeekdayOfMonthIndex is <= indexPath.item
  
  //    if (_weekOfMonthIndex == 0) {
  //        if (_firstWeekdayOfMonthIndex > indexPath.item) {
  //            dayCell.isCurrentMonth = NO;
  //        }
  //    } else if (_weekOfMonthIndex == _lastWeekOfMonthIndex) {
  //        if (indexPath.item > _lastWeekdayOfMonthIndex) {
  //            dayCell.isCurrentMonth = NO;
  //        }
  //
  //    } else {
  //        dayCell.isCurrentMonth = YES;
  //    }
  
  
  // Check if we have events loaded from the iOS calendar
  if (self.events) {
    
    id entry = self.events[dayDateComponents.day - 1]; // events array is 0-indexed.
    
    // If we have a non-null entry of our array of events at the current index,
    // store the entry in an
    if (entry != [NSNull null]) {
      NSMutableArray *eventContainer = (NSMutableArray *)entry;
      dayCell.events = eventContainer;
    }
    
  }
  
  return dayCell;
}


#pragma mark - UICollectionViewDelegate


- (BOOL)collectionView:(UICollectionView *)collectionView
shouldSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
  // Check to see if delegate implemented the shouldSelectItemAtIndexPath: method,
  // and return what the delegate implemented.
  if ([self.delegate respondsToSelector:@selector(collectionView:shouldSelectItemAtIndexPath:)]) {
    
    return [self.delegate collectionView:collectionView shouldSelectItemAtIndexPath:indexPath];
  }
  
  return YES;
}


- (void)collectionView:(UICollectionView *)collectionView
didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
  CalendarViewDayCell *dayCell = (CalendarViewDayCell *)[collectionView cellForItemAtIndexPath:indexPath];
  
  // If the cell we select is not the cell that's already selected, assign the properties to the correct date.
  if (!dayCell.isDaySelected) {
    
    _dateSelected = dayCell.date;
    dayCell.isDaySelected = YES;
  }
  // Or else if the selected cell is the same cell, de-select it.
  else {
    _dateSelected = nil;
    dayCell.isDaySelected = NO;
  }
  
  // Notify the delegate
  if ([self.delegate respondsToSelector:@selector(collectionView:didSelectItemAtIndexPath:)]) {
    [self.delegate collectionView:collectionView didSelectItemAtIndexPath:indexPath];
  }
  
  // Reload the collectionView to account for different items being selected.
  [self.collectionView reloadData];
}


#pragma mark - Custom Setters


- (void)setDisplayWeekDate:(NSDate *)weekDate
{
  NSDateComponents *components = [self.calendar components:NSCalendarUnitYearForWeekOfYear | NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitWeekOfYear | NSCalendarUnitWeekday fromDate:weekDate];
  [components setWeekday:1];
  NSDate *firstOfTheWeek = [self.calendar dateFromComponents:components];
  _displayWeekDate = firstOfTheWeek;
  NSLog(@"displayWeekDate = %@", _displayWeekDate);
  
  _todayDateComponents = [self.calendar components:NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay
                                          fromDate:[NSDate date]];
  
  _weekComponents = [self.calendar components:NSCalendarUnitYearForWeekOfYear | NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay | NSCalendarUnitWeekday | NSCalendarUnitWeekOfYear fromDate:_displayWeekDate];
  
  NSDateComponents *firstOfTheMonthComponents = [_weekComponents copy];
  
  NSDate *firstOfTheMonthDate = [self.calendar dateFromComponents:firstOfTheMonthComponents];
  
  // Get the index of the first weekday of the month being displayed
  _firstWeekdayOfMonthIndex = [self.calendar component:NSCalendarUnitWeekday
                                              fromDate:firstOfTheMonthDate] - 1;
  
  
  
  /***   Additional calculations for future reference   ***/
  
  NSDateComponents *lastOfTheMonthComponents = [_weekComponents copy];
  lastOfTheMonthComponents.month += 1;
  lastOfTheMonthComponents.day = 0;
  
  NSDate *lastOfTheMonthDate = [self.calendar dateFromComponents:lastOfTheMonthComponents];
  
  _lastWeekOfMonthIndex = [self.calendar component:NSCalendarUnitWeekOfMonth
                                          fromDate:lastOfTheMonthDate] - 1;
  
  _lastWeekdayOfMonthIndex = [self.calendar component:NSCalendarUnitWeekday
                                             fromDate:lastOfTheMonthDate] - 1;
  
  _weekOfYearIndex = [self.calendar component:NSCalendarUnitWeekOfYear
                                     fromDate:_displayWeekDate] - 1;
  
  _weekOfMonthIndex = [self.calendar component:NSCalendarUnitWeekOfMonth
                                      fromDate:firstOfTheMonthDate] - 1;
  
  _numberOfDaysInMonth = [self.calendar rangeOfUnit:NSCalendarUnitDay
                                             inUnit:NSCalendarUnitMonth
                                            forDate:_displayWeekDate].length;
  
  _numberOfWeeks = [self.calendar rangeOfUnit:NSCalendarUnitWeekOfYear
                                       inUnit:NSCalendarUnitYear
                                      forDate:_displayWeekDate].length;
  
  [self.collectionView reloadData];
}


- (NSCalendar *)calendar
{
  // Lazy loading of our calendar.
  if (!_calendar) {
    _calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
  }
  
  return _calendar;
}


// Custom setter which reloads the collection view.
- (void)setDateSelected:(NSDate *)dateSelected
{
  _dateSelected = dateSelected;
  [self.collectionView reloadData];
}


@end
























