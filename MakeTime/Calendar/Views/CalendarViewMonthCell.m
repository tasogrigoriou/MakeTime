//
//  CalendarViewMonthCell.m
//  MakeTime
//
//  Created by Anastasios Grigoriou on 2/5/17.
//  Copyright © 2017 Grigoriou. All rights reserved.


#import "CalendarViewMonthCell.h"
#import "CalendarHeaderView.h"
#import "CalendarViewDayCell.h"
#import "CollectionViewFlowLayout.h"


@interface CalendarViewMonthCell () <UICollectionViewDelegate, UICollectionViewDataSource>

@property (nonatomic) NSInteger firstWeekdayOfMonthIndex;
@property (nonatomic) NSInteger numberOfDaysInMonth;

@property (nonatomic, strong) NSDateComponents *monthComponents;
@property (nonatomic, strong) NSDateComponents *todayDateComponents;

@property (nonatomic, strong) NSCalendar *calendar;

@end


@implementation CalendarViewMonthCell


- (instancetype)initWithFrame:(CGRect)frame
{
  self = [super initWithFrame:frame];
  
  if (self) {
    
    // Init our monthFlowLayout using our designated initializer
    CollectionViewFlowLayout *monthFlowLayout = [[CollectionViewFlowLayout alloc]
                                                 initWithCollectionViewSize:frame.size
                                                 headerHeight:[CalendarHeaderView height]
                                                 scope:CalendarScopeMonth];
    
    self.collectionView = [[UICollectionView alloc]
                           initWithFrame:CGRectMake(0.0f, 0.0f, frame.size.width, frame.size.height)
                           collectionViewLayout:monthFlowLayout];
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


// Specify how many items (cells as defined by the days in the month) needed for our section
- (NSInteger)collectionView:(UICollectionView *)collectionView
     numberOfItemsInSection:(NSInteger)section
{
  if (!self.displayMonthDate) {
    return 0;
  }
  
  // Calculate how many days for the specific month we are in,
  // with the number of days in the month, plus the number of days that offset our starting date in the month.
  NSInteger numberOfDaysPlusStartOffset = _numberOfDaysInMonth + _firstWeekdayOfMonthIndex;
  
  // Calculate the remaining days needed to fill the end of the calendar (until Saturday),
  // by subtracting the number of offsetted days from the beginning of the calendar by 7.
  NSInteger remainingDaysToFillCalendar = 7 - (numberOfDaysPlusStartOffset % 7);
  
  
  return numberOfDaysPlusStartOffset + remainingDaysToFillCalendar;
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


- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView
                  cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
  CalendarViewDayCell *dayCell = (CalendarViewDayCell *)
  [collectionView dequeueReusableCellWithReuseIdentifier:NSStringFromClass([CalendarViewDayCell class])
                                            forIndexPath:indexPath];
  
  // Use NSDateComponents to draw out each cell item for each day in the month,
  // plus the offsetted days at beginning and end of each month.
  NSDateComponents *offsetComponents = [[NSDateComponents alloc] init];
  
  // Start at 0 to begin with our calculations below...
  offsetComponents.day = 0;
  
  // Take the date back to the first of the month we are in.
  offsetComponents.day -= _monthComponents.day -1;
  
  // Make room for the days of the previous month.
  // (ex. If the first day of the month is a Tue then we need 2 slots)
  offsetComponents.day -= _firstWeekdayOfMonthIndex;
  
  // Add the day offset corresponding to the cell about to be drawn (will increment up by 1 for each cell item).
  offsetComponents.day += indexPath.item;
  
  // Get the date for each day cell corresponding to the offsetComponents.
  NSDate *dayCellDate = [_calendar dateByAddingComponents:offsetComponents
                                                   toDate:_displayMonthDate
                                                  options:0];
  
  // Create components from our dayCellDate to display in our dayCell label.
  NSDateComponents *dayDateComponents = [_calendar
                                         components:NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay
                                         fromDate:dayCellDate];
  
  // Give each dayCell label text which displays the day from our dayDateComponents as a number.
  dayCell.label.text = [NSString stringWithFormat:@"%li", (long)dayDateComponents.day];
  
  // Assign the dayCell's date property to our NSDate.
  dayCell.date = dayCellDate;
  
  // Check to see if the dayCell we are at is today with a Boolean
  dayCell.isToday = (dayDateComponents.day == _todayDateComponents.day && dayDateComponents.month == _todayDateComponents.month && dayDateComponents.year == _todayDateComponents.year);
  
  dayCell.isDaySelected = NO;
  
  if (self.dateSelected) {
    NSLog(@"dateSelected is %@", self.dateSelected);
    
    // If we have a selected date, get its date components
    NSDateComponents *selectedDateComponents = [_calendar
                                                components:NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay
                                                fromDate:self.dateSelected];
    
    if (selectedDateComponents.year == dayDateComponents.year && selectedDateComponents.month == dayDateComponents.month) {
      
      // Check if the selected date is within the boundaries of our month.
      dayCell.isDaySelected =
      (BOOL)(indexPath.item == selectedDateComponents.day + _firstWeekdayOfMonthIndex - 1);
      
    }
  }
  
  // Check if the indexPath is within the boundaries of this month,
  // and if it is we know our dayCell is in the current month being displayed.
  if (_firstWeekdayOfMonthIndex <= indexPath.item &&
      indexPath.item < _firstWeekdayOfMonthIndex + _numberOfDaysInMonth) {
    
    dayCell.isCurrentMonth = YES;
    
  } else {
    dayCell.isCurrentMonth = NO;
  }
  
  // Check if dayCell is within current month and if we have events loaded from the iOS calendar
  if (dayCell.isCurrentMonth && self.events) {
    
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


- (void)setDisplayMonthDate:(NSDate *)monthDate
{
  _displayMonthDate = monthDate;
  NSLog(@"display month date is %@", _displayMonthDate);
  
  // Get the month components from our month that's being displayed.
  _monthComponents = [self.calendar components:NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay
                                      fromDate:_displayMonthDate];
  
  // Get the first day of the month that's being displayed.
  NSDateComponents *firstOfTheMonthComponents = [_monthComponents copy];
  firstOfTheMonthComponents.day = 1;
  
  // Convert the components into an NSDate that is the first date of that month.
  NSDate *firstOfTheMonthDate = [self.calendar dateFromComponents:firstOfTheMonthComponents];
  
  // Get the index of the first weekday of the month being displayed,
  // and make it zero-indexed.
  _firstWeekdayOfMonthIndex = [self.calendar component:NSCalendarUnitWeekday
                                              fromDate:firstOfTheMonthDate] - 1;
  
  // Calculate the number of days in the displayed month.
  _numberOfDaysInMonth = [self.calendar rangeOfUnit:NSCalendarUnitDay
                                             inUnit:NSCalendarUnitMonth
                                            forDate:_displayMonthDate].length;
  
  // Get today's date components
  _todayDateComponents = [self.calendar components:NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay
                                          fromDate:[NSDate date]];
  
  [self.collectionView reloadData];
}


- (NSCalendar *)calendar
{
  // Lazy loading of our calendar.
  if(!_calendar) {
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


















