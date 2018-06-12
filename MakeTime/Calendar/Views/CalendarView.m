//
//  CalendarView.m
//  MakeTime
//
//  Created by Anastasios Grigoriou on 2/4/17.
//  Copyright © 2017 Grigoriou. All rights reserved.


#import "CalendarView.h"
#import "CalendarViewMonthCell.h"
#import "CalendarViewWeekCell.h"
#import "CalendarViewDayCell.h"
#import <EventKit/EventKit.h>


@interface CalendarView () <UICollectionViewDelegate, UICollectionViewDataSource>

@property (strong, nonatomic) NSCalendar *calendar;
@property (strong, nonatomic) UICollectionView *collectionView;

@property (strong, nonatomic) NSDate *startDateCache;
@property (strong, nonatomic) NSDate *endDateCache;
@property (strong, nonatomic) NSDate *startOfMonthCache;
@property (strong, nonatomic) NSDate *startOfWeekCache;

@property (nonatomic) NSInteger numberOfItemsInSectionCache;

// readonly is used when you don’t want to allow a property to be changed via a setter method
@property (readonly, nonatomic) CalendarViewMonthCell *currentMonthCell;
@property (readonly, nonatomic) CalendarViewWeekCell *currentWeekCell;

@property (readonly, nonatomic) NSInteger monthIndex;
@property (readonly, nonatomic) NSUInteger cellDisplayedIndex;

@property (strong, nonatomic) EKEventStore *store;
@property (strong, nonatomic) NSArray *events; // EKEventStore storage

@property (assign, nonatomic) BOOL manualScroll;

@end

@implementation CalendarView

@dynamic monthDisplayed;
@dynamic weekDisplayed;


- (id)initWithFrame:(CGRect)frame
{
  self = [super initWithFrame:frame];
  
  if (self) {
    [self setup];
  }
  
  return self;
}


- (void)awakeFromNib
{
  [super awakeFromNib];
  [self setup];
}


- (void)setup
{
  /*** Create and configure the CalendarView / FlowLayout which will render the days as cells. ***/
  
  _calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
  
  UICollectionViewFlowLayout *flowLayout = [UICollectionViewFlowLayout new];
  
  flowLayout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
  flowLayout.itemSize = self.frame.size;
  
  flowLayout.minimumInteritemSpacing = 0.0f;
  flowLayout.minimumLineSpacing = 0.0f;
  
  // Important to make origin of the CalendarView at (0, 0)
  CGRect frame = self.frame;
  frame.origin = CGPointZero;
  
  self.collectionView = [[UICollectionView alloc] initWithFrame:frame
                                           collectionViewLayout:flowLayout];
  
  // Have our CalendarView be the collectionView's delegate/data source.
  self.collectionView.delegate = self;
  self.collectionView.dataSource = self;
  
  self.collectionView.pagingEnabled = YES;
  self.collectionView.showsVerticalScrollIndicator = NO;
  self.collectionView.showsHorizontalScrollIndicator = NO;
  
  self.backgroundColor = [UIColor clearColor];
//  self.collectionView.backgroundColor = [UIColor whiteColor];
  self.collectionView.backgroundColor = [UIColor clearColor];
  
  // comment these lines out if you don't want a border around the CalendarView.
  self.layer.borderWidth = 1.0;
  self.layer.borderColor = [UIColor colorWithWhite:0.8 alpha:1.0].CGColor;
  
  [self.collectionView registerClass:[CalendarViewMonthCell class]
          forCellWithReuseIdentifier:NSStringFromClass([CalendarViewMonthCell class])];
  [self.collectionView registerClass:[CalendarViewWeekCell class]
          forCellWithReuseIdentifier:NSStringFromClass([CalendarViewWeekCell class])];
  
  [self addSubview:self.collectionView];
}


#pragma mark - UICollectionViewDataSource


// Every month will be a section and every day will be a cell,
// We only need one section to display our month section.
- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
  if (self.dataSource) {
    
    // Call the delegate object startDate and cache it in the class’s local variable _startDateCache.
    // (the class which conforms to the delegate is required to implement the startDate data source method).
    _startDateCache = self.dataSource.startDate;
    
    NSDateComponents *components = [_calendar
                                    components:NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay | NSCalendarUnitWeekday | NSCalendarUnitWeekOfYear
                                    fromDate:_startDateCache];
    switch (_scope) {
        // For our month view, set the first of the month as the base date for the calendar
      case CalendarScopeMonth: {
        components.day = 1;
        _startOfMonthCache = [_calendar dateFromComponents:components];
        break;
      }
        // For our week view, set the current day to be the base date for the calendar
      case CalendarScopeWeek: {
        _startOfWeekCache = [_calendar dateFromComponents:components];
        break;
      }
    }
    
    // If we implement the data source method "endDate", cache it in the class's local variable _endDateCache.
    if ([self.dataSource respondsToSelector:@selector(endDate)]) {
      _endDateCache = self.dataSource.endDate;
    }
    // If we do not implement endDate, create a NSDateComponents with the default number of months (24).
    else {
      NSDateComponents *offsetComponents = [[NSDateComponents alloc] init];
      offsetComponents.month = 24;
      
      // Increment our offsetComponents by one month,
      // then set its day as one less than the first day of the 25th month.
      offsetComponents.month += 1;
      offsetComponents.day = 0;
      
      // and set the class's local variable _endDateCache as the last day of endDate's month.
      _endDateCache = [_calendar dateByAddingComponents:offsetComponents
                                                 toDate:_startDateCache
                                                options:0];
    }
  }
  
  // If we have a start date cached, return 1 section (month) for our calendar.
  return _startDateCache ? 1 : 0;
}


// Make calculations in this method that gets called for each section (month).
- (NSInteger)collectionView:(UICollectionView *)collectionView
     numberOfItemsInSection:(NSInteger)section
{
  if (self.delegate) {
    
    switch (_scope) {
      case CalendarScopeMonth: {
        // If we have a delegate, notify it that the user scrolled to another month,
        // and assign the dataSource object's startDate to the first date of that month.
        [self.delegate calendarController:self
                         didScrollToMonth:self.dataSource.startDate];
        
        // Set the number of items in each section (month) to be the number of months between startDate/endDate.
        _numberOfItemsInSectionCache = [_calendar components:NSCalendarUnitMonth
                                                    fromDate:_startDateCache
                                                      toDate:_endDateCache
                                                     options:0].month + 1;
        break;
      }
      case CalendarScopeWeek: {
        [self.delegate calendarController:self
                          didScrollToWeek:self.dataSource.startDate];
        
        // Set the number of items in each section (week) to be the number of weeks between startDate/endDate.
        _numberOfItemsInSectionCache = [_calendar components:NSCalendarUnitWeekOfYear
                                                    fromDate:_startDateCache
                                                      toDate:_endDateCache
                                                     options:0].weekOfYear + 1;
        break;
      }
    }
  }
  
  if (self.showsEvents) {
//    [self loadEventsInCalendar];
  }
  
  return _numberOfItemsInSectionCache;
}


- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView
                  cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
  switch (_scope) {
    case CalendarScopeMonth: {
      // Provide a reusable cell from our custom CalendarViewMonthCell class.
      CalendarViewMonthCell *monthCell = (CalendarViewMonthCell *)
      [collectionView dequeueReusableCellWithReuseIdentifier:NSStringFromClass([CalendarViewMonthCell class])
                                                forIndexPath:indexPath];
      
      NSDateComponents *offsetComponents = [[NSDateComponents alloc] init];
      
      // Offset by a month to make sure displayMonthDate is updated for each call to cellForItemAtIndexPath:
      // (each time we get a new indexPath item for the month cell).
      offsetComponents.month = indexPath.item;
      monthCell.displayMonthDate = [_calendar dateByAddingComponents:offsetComponents
                                                              toDate:_startOfMonthCache
                                                             options:0];
      
      // Assign our CalendarView to be the monthCell's delegate,
      // also assign the dateSelected property from CalendarViewMonthCell to our (CalendarView) dateSelected property.
      monthCell.delegate = self;
      monthCell.dateSelected = self.dateSelected;
      
      // Assign monthCell's events to the array of the specified month we are in (at the indexPath item's month cell).
      if (_events) {
        monthCell.events = _events[indexPath.item];
      }
      
      return monthCell;
    }
    case CalendarScopeWeek: {
      CalendarViewWeekCell *weekCell = (CalendarViewWeekCell *)
      [collectionView dequeueReusableCellWithReuseIdentifier:NSStringFromClass([CalendarViewWeekCell class])
                                                forIndexPath:indexPath];
      
      NSDateComponents *offsetComponents = [[NSDateComponents alloc] init];
      offsetComponents.weekOfYear = indexPath.item;
      
      weekCell.displayWeekDate = [_calendar dateByAddingComponents:offsetComponents
                                                            toDate:_startOfWeekCache
                                                           options:0];
      weekCell.delegate = self;
      weekCell.dateSelected = self.dateSelected;
      
      if(_events) {
        weekCell.events = _events[indexPath.item];
      }
      
      return weekCell;
    }
  }
}


#pragma mark - UICollectionViewDelegate


- (void)collectionView:(UICollectionView *)collectionView
didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
  // Make sure we are referring to day cells, not month/week cells
  if (collectionView != self.collectionView) {
    
    CalendarViewDayCell *dayCell = (CalendarViewDayCell *)[collectionView cellForItemAtIndexPath:indexPath];
    
    // If user selected the cell at the index path,
    // assign the CalendarView's dateSelected property to the dayCell's date, if else, let go of date.
    if (dayCell.isDaySelected) {
      _dateSelected = dayCell.date;
    } else {
      _dateSelected = nil;
    }
    
    // If there was a date selected, notify the delegate of the changes.
    if ([self.delegate respondsToSelector:@selector(calendarController:didSelectDay:)]) {
      [self.delegate calendarController:self
                           didSelectDay:_dateSelected];
    }
  }
}


- (BOOL)collectionView:(UICollectionView *)collectionView
shouldSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
  CalendarViewDayCell *dayCell = (CalendarViewDayCell *)[collectionView cellForItemAtIndexPath:indexPath];
  
  // If we have a month scope and the day is not within the current month, we should not be able to select that date.
  if (_scope == CalendarScopeMonth) {
    if (!dayCell.isCurrentMonth) {
      return NO;
    }
  }
  
  return YES;
}


#pragma mark - UIScrollViewDelegate


- (void)scrollViewDidEndScrollingAnimation:(UIScrollView *)scrollView
{
  // Cast self (UIView) as a scroll view, and notify the delegate that the scroll view has ended decelerating.
  [self scrollViewDidEndDecelerating:(UIScrollView *)self];
}


- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
  if (self.delegate) {
    
    switch (_scope) {
      case CalendarScopeMonth: {
        // Notify the delegate to update the displayMonthDate in the currentMonthCell when user ends scrolling.
        if ([self.delegate respondsToSelector:@selector(calendarController:didScrollToMonth:)]) {
          [self.delegate calendarController:self
                           didScrollToMonth:self.currentMonthCell.displayMonthDate];
        }
        break;
      }
      case CalendarScopeWeek: {
        if ([self.delegate respondsToSelector:@selector(calendarController:didScrollToWeek:)]) {
          [self.delegate calendarController:self
                            didScrollToWeek:self.currentWeekCell.displayWeekDate];
        }
        break;
      }
    }
  }
}


#pragma mark - Custom Setters


- (void)setScope:(CalendarScope)scope
{
  _scope = scope;
}


// Make sure both if / else if conditions are satisfied before user can set the dateSelected property.
- (void)setDateSelected:(NSDate *)dateSelected
               animated:(BOOL)animated
{
  // If the startDate is larger than the dateSelected, exit
  if ([dateSelected compare:_startDateCache] == NSOrderedAscending) {
    return;
    
    // if we implemented an endDate for the calendar and the dateSelected is larger, exit
  } else if (_endDateCache && [dateSelected compare:_endDateCache] == NSOrderedDescending) {
    return;
  }
  
  _dateSelected = dateSelected;
  
  switch (_scope) {
    case CalendarScopeMonth: {
      
      // Call setMonthDisplayed: to also get the month when user calls setDateSelected.
      [self setMonthDisplayed:dateSelected animated:animated];
      
      // Get the month components from the dateSelected,
      // and call .month to get number of months for our index.
      NSInteger month = [_calendar components:NSCalendarUnitMonth
                                     fromDate:_startDateCache
                                       toDate:dateSelected
                                      options:0].month;
      
      // Call monthCellForMonthIndex: to get a monthCell's instance at the specified index.
      CalendarViewMonthCell *monthCell = [self monthCellForMonthIndex:month];
      
      // Update the date selected property from CalendarViewMonthCell.
      monthCell.dateSelected = _dateSelected;
      
      break;
    }
    case CalendarScopeWeek: {
      
//      [self setWeekDisplayed:dateSelected animated:animated];
      
      NSInteger week = [_calendar components:NSCalendarUnitWeekOfYear
                                    fromDate:_startDateCache
                                      toDate:dateSelected
                                     options:0].weekOfYear;
      
      CalendarViewWeekCell *weekCell = [self weekCellForWeekIndex:week];
      weekCell.dateSelected = _dateSelected;
      
      break;
    }
  }
}


- (void)setDateSelected:(NSDate *)dateSelected
{
  [self setDateSelected:dateSelected animated:NO];
}


- (CalendarViewMonthCell *)monthCellForMonthIndex:(NSInteger)index
{
  // Get a month cell from our collectionView at its specified indexPath.
  NSIndexPath *indexPath = [NSIndexPath indexPathForItem:index inSection:0];
  return (CalendarViewMonthCell *)[self.collectionView cellForItemAtIndexPath:indexPath];
}


- (CalendarViewWeekCell *)weekCellForWeekIndex:(NSInteger)index
{
  // Get a week cell from our collectionView at its specified indexPath.
  NSIndexPath *indexPath = [NSIndexPath indexPathForItem:index inSection:0];
  return (CalendarViewWeekCell *)[self.collectionView cellForItemAtIndexPath:indexPath];
}


// Get the current month's cell to display the month above the weekday labels.
- (CalendarViewMonthCell *)currentMonthCell
{
  // Get the width of the month cell from our collection view's layout
  CGFloat monthCellWidth = ((UICollectionViewFlowLayout *)self.collectionView.collectionViewLayout).itemSize.width;
  
  // Get pageNumber (whichever section/month we are in),
  // by dividing the difference between the origin of the collectionView and the current scroll view, with the monthCell label's width.
  CGFloat pageNumberRoundedDown = floor(self.collectionView.contentOffset.x / monthCellWidth);
  
  // Return a monthCell at the pageNumber (whichever month we are in) index.
  return (CalendarViewMonthCell *)[self.collectionView
                                   cellForItemAtIndexPath:[NSIndexPath indexPathForItem:pageNumberRoundedDown
                                                                              inSection:0]];
}


- (CalendarViewWeekCell *)currentWeekCell
{
  CGFloat weekCellWidth = ((UICollectionViewFlowLayout *)self.collectionView.collectionViewLayout).itemSize.width;
  
  CGFloat pageNumberRoundedDown = floor(self.collectionView.contentOffset.x / weekCellWidth);
  
  return (CalendarViewWeekCell *)[self.collectionView
                                  cellForItemAtIndexPath:[NSIndexPath indexPathForItem:pageNumberRoundedDown
                                                                             inSection:0]];
}


// Get a visual reference to the calendar.
// monthDisplayed is a date object representing the first of the month.
- (NSDate *)monthDisplayed
{
  // Return nil if not loaded with correct frame
  if (CGRectIsEmpty(self.collectionView.frame)) {
    return nil;
  }
  // Return nil if we startDate hasn't been set
  if (!_startDateCache) {
    return nil;
  }
  
  NSDateComponents *components = [[NSDateComponents alloc] init];
  
  // Offset by one month less using the monthCell index (first components.month will be 0)
  components.month = self.cellDisplayedIndex;
  
  // Return an NSDate that gives us the month displayed in relation to our start date
  return [_calendar dateByAddingComponents:components toDate:_startDateCache options:0];
}


- (NSDate *)weekDisplayed
{
  if (CGRectIsEmpty(self.collectionView.frame)) {
    return nil;
  }
  if (!_startDateCache) {
    return nil;
  } 
  
  // Get the week of the year from the index of our WeekCell
  NSDateComponents *weekOfYearComponents = [NSDateComponents new];
  weekOfYearComponents.weekOfYear = self.cellDisplayedIndex;
  NSDate *dateFromWeekOfYear = [_calendar dateByAddingComponents:weekOfYearComponents
                                                          toDate:_startDateCache
                                                         options:0];
  // then, re-set the date to the first of the week (Sunday)
  NSDateComponents *firstOfTheWeekComponents = [self.calendar components:NSCalendarUnitYearForWeekOfYear | NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitWeekOfYear | NSCalendarUnitWeekday
                                                                fromDate:dateFromWeekOfYear];
  [firstOfTheWeekComponents setWeekday:1];
  NSDate *firstOfTheWeekDate = [_calendar dateFromComponents:firstOfTheWeekComponents];
  return firstOfTheWeekDate;
}


- (void)setMonthDisplayed:(NSDate *)monthDisplayed animated:(BOOL)animated
{
  if (!self.monthDisplayed) {
    return;
  }
  
  // Check if monthDisplayed date is between our startDate and endDate
  if ([monthDisplayed compare:_startDateCache] == NSOrderedAscending) {
    return;
  } else if (_endDateCache && [monthDisplayed compare:_endDateCache] == NSOrderedDescending) {
    return;
  }
  
  // Calculate difference between startDateCache and monthDisplayed dates
  NSDateComponents *differenceComponents = [_calendar components:NSCalendarUnitMonth
                                                        fromDate:_startDateCache
                                                          toDate:monthDisplayed
                                                         options:0];
  
  // First check if we set our monthDisplayed to the same month as the startDateCache using our cell's index
  if (differenceComponents.month != self.cellDisplayedIndex) {
    
    // Create a CGRect that will be able to scroll left/right,
    // from the monthDisplayed (today) to startDate (left) all the way to endDate (right)
    CGRect rectToScroll = CGRectZero;
    rectToScroll.size = self.collectionView.bounds.size;
    rectToScroll.origin.x = differenceComponents.month * self.collectionView.bounds.size.width;
    
    _manualScroll = YES;
    
    // Scroll the collectionView from our startDateCache to monthDisplayed with/without animation
    [self.collectionView scrollRectToVisible:rectToScroll animated:animated];
  }
}


- (void)setWeekDisplayed:(NSDate *)weekDisplayed animated:(BOOL)animated
{
  if (!self.weekDisplayed) {
    return;
  }
  
  if ([weekDisplayed compare:_startDateCache] == NSOrderedAscending) {
    return;
  } else if (_endDateCache && [weekDisplayed compare:_endDateCache] == NSOrderedDescending) {
    return;
  }
  
  NSDateComponents *differenceComponents = [_calendar components:NSCalendarUnitWeekOfYear
                                                        fromDate:_startDateCache
                                                          toDate:weekDisplayed
                                                         options:0];
  
  if (differenceComponents.weekOfYear != self.cellDisplayedIndex) {
    
    CGRect rectToScroll = CGRectZero;
    rectToScroll.size = self.collectionView.bounds.size;
    rectToScroll.origin.x = differenceComponents.weekOfYear * self.collectionView.bounds.size.width;
    
    _manualScroll = YES;
    [self.collectionView scrollRectToVisible:rectToScroll animated:animated];
  }

}


- (void)setMonthDisplayed:(NSDate *)monthDisplayed
{
  [self setMonthDisplayed:monthDisplayed animated:NO];
}


- (void)setWeekDisplayed:(NSDate *)weekDisplayed
{
  [self setWeekDisplayed:weekDisplayed animated:NO];
}


- (void)setDataSource:(id<CalendarViewDataSource>)dataSource
{
  _dataSource = dataSource;
  
  // If the view has already been presented, refresh with the new dataSource
  if (self.superview) {
    [self.collectionView reloadData];
  }
}


#pragma mark - Utility Methods


// Calculate index of MonthCell based on where we are offsetted from the first cell.
- (NSUInteger)cellDisplayedIndex
{
  return (NSUInteger)(self.collectionView.contentOffset.x / self.collectionView.frame.size.width);
}


- (void)setShowsEvents:(BOOL)showsEvents
{
  // If we set showsEvents to yes and the view has fetched dates from the delegates, call loadEventsInCalendar
  if (showsEvents && !_showsEvents && _startDateCache) {
//    [self loadEventsInCalendar];
  }
  
  _showsEvents = showsEvents;
}


//- (void)loadEventsInCalendar
//{
//  // Lazy load the EKEventStore
//  if (!_store) {
//    _store = [[EKEventStore alloc] init];
//  }
//  
//  void(^fetchEventsBlock)(void) = ^{
//    
//    // Create a predicate that searches for events in the event store within our startDate and endDate
//    NSPredicate *predicate = [_store predicateForEventsWithStartDate:_startDateCache
//                                                             endDate:_endDateCache
//                                                           calendars:nil];
//    // Store all events in an array matching the predicate
//    NSArray *eventsArray = [_store eventsMatchingPredicate:predicate];
//    
//    /*** Process Events ***/
//    
//    // Get the number of items in section[0], the current month.
//    // (will return 28 for February, 30 for March, etc)
//    NSInteger numberOfItems = [self collectionView:self.collectionView numberOfItemsInSection:0];
//    
//    // Initialize a mutable array with the capacity to hold the number of items (days) in the current month.
//    NSMutableArray *eventsByMonth = [NSMutableArray arrayWithCapacity:numberOfItems];
//    
//    
//    // By the end of both for loops...
//    // we have an empty eventsByMonth array that is essentially a container for each month's events indexed by which day the event falls on.
//    for (int i = 0; i < numberOfItems; i++) {
//      
//      NSMutableArray *eventsByDay = [NSMutableArray arrayWithCapacity:31];
//      
//      for (int j = 0; j < 31; j++) {
//        
//        NSMutableArray *eventsContainer = [NSMutableArray array];
//        [eventsByDay addObject:eventsContainer];
//      }
//      
//      [eventsByMonth addObject:eventsByDay];
//      
//    }
//    
//    // Loop through all events,
//    // adding each event to the eventsByMonth array indexed by the month and the day the event falls on.
//    for (EKEvent *event in eventsArray) {
//      
//      // Get the month and day date components from our startDateCache to the event's startDate.
//      NSDateComponents *components = [_calendar components:NSCalendarUnitMonth | NSCalendarUnitDay
//                                                  fromDate:_startDateCache
//                                                    toDate:event.startDate
//                                                   options:0];
//      
//      // Create an array to hold the events for each month
//      NSMutableArray *monthMutableArray = (NSMutableArray *)eventsByMonth[components.month];
//      
//      // Create a container to hold the the events within our monthMutableArray at the correct index (month).
//      NSMutableArray *eventsContainer = (NSMutableArray *)monthMutableArray[components.day];
//      
//      // Add each event from the EKEventStore into the eventsContainer, which is inside the monthMutableArray.
//      [eventsContainer addObject:event];
//    }
//    
//    self.events = [NSArray arrayWithArray:eventsByMonth];
//    
//    // Temporarily take weak ownership of our self (CalendarView) to avoid strong reference cycle within block.
//    //        __weak CalendarView *weakSelf = self;
//    
//    
//    /********* Works if we press icon right away (while collectionView is reloading data???) ************/
//    
//    
//    dispatch_async(dispatch_get_main_queue(), ^{
//      
//      //            CalendarView *strongSelf = weakSelf;
//      
//      // Update the UI on main thread
//      //            [strongSelf.collectionView reloadData];
//      
//    });
//  };
//  
//  dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
//    
//    // If we dont have authorization from the user to get access to their iOS calendar, ask for authorization
//    if ([EKEventStore authorizationStatusForEntityType:EKEntityTypeEvent] != EKAuthorizationStatusAuthorized) {
//      
//      [_store requestAccessToEntityType:EKEntityTypeEvent
//                             completion:^(BOOL granted, NSError *error) {
//                               
//                               if (granted) {
//                                 
//                                 fetchEventsBlock();
//                                 
//                               } else {
//                                 NSLog(@"%@", [error localizedDescription]);
//                               }
//                               
//                             }];
//    }
//    // If we already have authorization, just call the fetch events block
//    else {
//      fetchEventsBlock();
//    }
//    
//  });
//}


@end





























