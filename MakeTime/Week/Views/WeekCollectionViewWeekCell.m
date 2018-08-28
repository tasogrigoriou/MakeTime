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

@interface WeekCollectionViewWeekCell () <UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, WeekCollectionViewLayoutDelegate>

@property (strong, nonatomic) NSCalendar *calendar;
@property (strong, nonatomic) NSDateFormatter *dateFormatter;

@property (strong, nonatomic) AppDelegate *appDelegate;
@property (strong, nonatomic) NSArray *customCalendars;
@property (strong, nonatomic) NSArray *customEvents;

@property (strong, nonatomic) NSArray *eventComponentsArray;
@property (strong, nonatomic) NSArray *convertedEventComponentsArray;

@end


@implementation WeekCollectionViewWeekCell


#pragma mark - View Lifecycle


- (instancetype)initWithFrame:(CGRect)frame {
   if (self = [super initWithFrame:frame]) {
      [self configureViewAndCollectionView];
   }
   
   return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder {
   self = [super initWithCoder:coder];
   if (self) {
      [self configureViewAndCollectionView];
   }
   return self;
}


#pragma mark - UICollectionViewDataSource


- (NSInteger)collectionView:(UICollectionView *)collectionView
     numberOfItemsInSection:(NSInteger)section {
   [self loadCustomCalendarsAndEvents];
   
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
   
   // Get the sunday from the selectedDate in the current week we are in
   NSDate *startOfWeek = [self startOfWeekOfDate:self.selectedDate];
   
   NSDateComponents *comps = [NSDateComponents new];
   comps.day = 0;
   comps.day += indexPath.item;
   NSDate *weekDate = [self.calendar dateByAddingComponents:comps
                                                     toDate:startOfWeek
                                                    options:0];
   
   [self.dateFormatter setLocalizedDateFormatFromTemplate:@"EEEE MM:dd"];
   NSString *stringDate = [self.dateFormatter stringFromDate:weekDate];
   
   NSArray *foo = [stringDate componentsSeparatedByString:@" "];
   NSString *firstBit = [foo objectAtIndex:0];
   NSString *secondBit = [foo objectAtIndex:1];
   NSString *whole = [NSString stringWithFormat:@"%@\n%@", firstBit, secondBit];
   
   view.weekdayLabel.text = whole;
   
   return view;
}


#pragma mark - UICollectionViewDelegate


- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    EKEvent *event = self.customEvents[indexPath.item];
    [self.delegate weekCell:self didSelectEvent:event];
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
   NSMutableArray *convertedEventComponentsArray = [NSMutableArray new];
   
   for (EventComponents *eventComponent in self.eventComponentsArray) {
      
      NSDate *startOfDate = [self.calendar startOfDayForDate:eventComponent.startDate];
      NSDateComponents *comps = [NSDateComponents new];
      comps.day = 1;
      NSDate *startOfNextDay = [self.calendar dateByAddingComponents:comps toDate:startOfDate options:0];
      
      while ([eventComponent.endDate compare:startOfNextDay] == NSOrderedDescending) {
          EventComponents *newEventComponent = [EventComponents eventWithTitle:@""
                                                                       calendar:eventComponent.calendar
                                                                      startDate:startOfNextDay
                                                                        endDate:eventComponent.endDate
                                                                          color:eventComponent.color
                                                                     identifier:eventComponent.identifier];
         // Update startOfNextDay to be next next day (until the event's endDate is smaller than the nextDay)
         startOfNextDay = [self.calendar dateByAddingComponents:comps toDate:startOfNextDay options:0];
         
         [convertedEventComponentsArray addObject:newEventComponent];
      }
      
      [convertedEventComponentsArray addObject:eventComponent];
   }
   
   return (NSArray *)convertedEventComponentsArray;
}


#pragma mark - Private Methods


- (void)configureViewAndCollectionView {
   self.backgroundColor = [UIColor clearColor];
   
   WeekCollectionViewLayout *layout = [WeekCollectionViewLayout new];
   CGRect frame = self.frame;
   frame.origin = CGPointZero;
   NSLog(@"weekviewlayout width = %f , weekviewlayout height = %f", frame.size.width, frame.size.height);
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
}

- (void)loadCustomCalendarsAndEvents {
   if ([[NSUserDefaults standardUserDefaults] objectForKey:@"eventStoreGranted"]) {
      
      self.customCalendars = [self.appDelegate.eventManager loadCustomCalendars];
      self.customEvents = [self.appDelegate.eventManager getEventsOfAllCalendars:self.customCalendars
                                                                  thatFallInWeek:self.selectedDate];
      
      // Get converted event comps and sort them by startDate
      self.eventComponentsArray = [self copyCustomEventsIntoEventComponents];
      NSArray *convertedEventArray = [self getConvertedEventComponents];
      NSSortDescriptor *dateDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"startDate" ascending:YES];
      self.convertedEventComponentsArray = [convertedEventArray sortedArrayUsingDescriptors:@[dateDescriptor]];
      
      for (EKEvent *event in self.customEvents) {
         NSLog(@"custom event = %@", event);
      }
      
      for (EventComponents *eventComponent in self.convertedEventComponentsArray) {
         NSLog(@"eventComponent title = %@", eventComponent.title);
         NSLog(@"eventComponent startDate = %@", eventComponent.startDate);
         NSLog(@"eventComponent endDate = %@", eventComponent.endDate);
      }
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


@end
