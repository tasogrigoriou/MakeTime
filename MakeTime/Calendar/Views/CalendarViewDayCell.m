//
//  CalendarViewDayCell.m
//  MakeTime
//
//  Created by Anastasios Grigoriou on 2/5/17.
//  Copyright © 2017 Grigoriou. All rights reserved.
//

#import "CalendarViewDayCell.h"


@implementation CalendarViewDayCell


- (instancetype)initWithFrame:(CGRect)frame
{
  self = [super initWithFrame:frame];
  
  if (self) {
    
    /*** Setup label ***/
    
    // Get the min value between the frame's width or height.
    CGFloat labelSideLength = MIN(frame.size.width, frame.size.height);
    CGRect labelFrame = CGRectZero;
    labelFrame.size = CGSizeMake(labelSideLength, labelSideLength);
    
    self.label = [[UILabel alloc] init];
    self.label.frame = labelFrame;
    self.label.textAlignment = NSTextAlignmentCenter;
    self.label.font = [UIFont fontWithName:@"Helvetica" size:14.0f];
    self.label.backgroundColor = [UIColor clearColor];
    
    self.label.center = CGPointMake(frame.size.width / 2.0f, frame.size.height / 2.0f);
    self.label.minimumScaleFactor = 10.0f;
    self.label.adjustsFontSizeToFitWidth = YES;
    
    /*** Setup selected mark view ***/
    
    // Make the selectedMarkView's frame the same as the label's frame, but with 3.0f insets.
    _selectedMarkView = [[UIView alloc] initWithFrame:CGRectInset(self.label.frame, 6.0f, 6.0f)];
    _selectedMarkView.clipsToBounds = YES;
    
    // Make the selectedMarkView have rounded corners.
    _selectedMarkView.layer.cornerRadius = _selectedMarkView.frame.size.width / 2.0f;
    _selectedMarkView.backgroundColor = [UIColor brownColor];
    
    [self addSubview:_selectedMarkView];
    [self addSubview:self.label];
    
    /*** Setup today mark view ***/
    
    // Mark today with a red dot below the center of the label frame.
    _todayMarkView = [[UIView alloc] initWithFrame:CGRectMake(0, self.frame.size.height - 12.0f, 7.0f, 7.0f)];
    _todayMarkView.center = CGPointMake(self.bounds.size.width / 2.0f, _todayMarkView.center.y);
    _todayMarkView.backgroundColor = [UIColor redColor];
    _todayMarkView.layer.cornerRadius = _todayMarkView.frame.size.width * 0.6f;
    
    [self addSubview:_todayMarkView];
    
    /*** Setup events mark view ***/
    
    _eventsMarksView = [[UIView alloc]
                        initWithFrame:CGRectMake(6.0f, 6.0f, self.frame.size.height - 6.0f, 6.0f)];
    _eventsMarksView.backgroundColor = [UIColor clearColor];
    
    CGFloat xPosition = 0.0f;
    
    CGFloat oneThird = self.frame.size.height - 6.0 / 3.0;
    
    // Add a dot for every event (up to 3).
    for (int i = 0; i < 3; i++) {
      UIView *eventCircleView = [[UIView alloc] initWithFrame:CGRectMake(xPosition, 0.0, 6.0f, 6.0f)];
      eventCircleView.layer.cornerRadius = 3.0f;
      eventCircleView.clipsToBounds = YES;
      eventCircleView.tag = 100 + i;
      eventCircleView.backgroundColor = [UIColor clearColor];
      xPosition += oneThird;
      
      [_eventsMarksView addSubview:eventCircleView];
    }
    
    [self addSubview:_eventsMarksView];
    
    
    self.isDaySelected = NO;
  }
  
  return self;
}


#pragma mark - Custom Setters


// setEvents: will take care of storing and displaying the events.
- (void)setEvents:(NSArray *)events
{
  _events = events;
  
  for (int i = 0; i < _events.count; i++) {
    UIView *circleEventView = [_eventsMarksView viewWithTag:(100 + i)];
    circleEventView.backgroundColor = [UIColor blueColor];
  }
}


- (void)setIsCurrentMonth:(BOOL)isCurrentMonth
{
  _isCurrentMonth = isCurrentMonth;
  
  // If we are in the current month...
  if (_isCurrentMonth) {
    _todayMarkView.backgroundColor = [UIColor redColor];
    self.label.textColor = [UIColor darkGrayColor];
    
  } else {
    _todayMarkView.backgroundColor = [UIColor lightGrayColor];
    self.label.textColor = [UIColor lightGrayColor];
    
    // If you want to hide the days not in current month...
    // self.label.textColor = [UIColor lightGrayColor];
  }
  
  // If a day is selected, set the label's textColor white.
  if (_isDaySelected) {
    self.label.textColor = [UIColor whiteColor];
  }
}


// Prepare the label for reuse.
- (void)prepareForReuse
{
  [super prepareForReuse];
  
  // Make every eventCircleView (which is a subview of eventsMarksView) clear color background.
  for (UIView *circleEventMark in _eventsMarksView.subviews) {
    circleEventMark.backgroundColor = [UIColor clearColor];
  }
}

- (void)setIsToday:(BOOL)isToday
{
  _isToday = isToday;
  
  // Hide the red mark view if the day is today.
  if (_isToday) {
    _todayMarkView.hidden = NO;
  } else {
    _todayMarkView.hidden = YES;
  }
  
}


- (void)setIsDaySelected:(BOOL)isDaySelected
{
  _isDaySelected = isDaySelected;
  
  // If the day is selected, make sure selectedMarkView is visible and todayMarkView hidden.
  if (isDaySelected) {
    
    _selectedMarkView.hidden = NO;
    _todayMarkView.hidden = YES;
    
    self.label.textColor = [UIColor whiteColor];
    
  } else {
    
    self.label.textColor = [UIColor darkGrayColor];
    
    // Make selectedMarkView hidden if day is not selected.
    _selectedMarkView.hidden = YES;
    
    // Pass value to call setter which defines the opacity of the Today label.
    self.isToday = _isToday;
    
  }
}


@end


























