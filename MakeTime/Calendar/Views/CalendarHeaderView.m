//
//  CalendarHeaderView.m
//  MakeTime
//
//  Created by Anastasios Grigoriou on 2/5/17.
//  Copyright © 2017 Grigoriou. All rights reserved.
//

#import "CalendarHeaderView.h"

@implementation CalendarHeaderView


- (instancetype)initWithFrame:(CGRect)frame
{
  self = [super initWithFrame:frame];
  
  if (self) {
    self.backgroundColor = [UIColor lightGrayColor];
//    self.backgroundColor = [UIColor clearColor];
    
    // Assign an xpos/lwidth to account for change of x-position in for-in loop
    CGFloat xPosition = 0.0f;
    CGFloat lwidth = frame.size.width / 7.0f;
    CGFloat lheight = frame.size.height;
    
    // Init a NSDateFormatter to loop through an array of the days in a week.
    NSDateFormatter *dateFormatter = [NSDateFormatter new];
    
    for (NSString *weekday in dateFormatter.weekdaySymbols) {
      
      CGRect dayRect = CGRectMake(xPosition, 0.0f, lwidth, lheight);
      UILabel *dayLabel = [[UILabel alloc] initWithFrame:dayRect];
      
      dayLabel.backgroundColor = [UIColor clearColor];
      dayLabel.textColor = [UIColor whiteColor];
      
      dayLabel.font = [UIFont fontWithName:@"Helvetica" size:12.0f];
      dayLabel.textAlignment = NSTextAlignmentCenter;
      
      // Assign the dayLabel's text to be a substring of the weekday in weekdaySymbols.
      dayLabel.text = [weekday substringToIndex:3].uppercaseString;
      
      [self addSubview:dayLabel];
      
      // Increment up the x-position for each weekday label (1/7)
      xPosition += lwidth;
    }
    
  }
  
  return self;
}


// Set class method "height" to 30.0f
+ (CGFloat)height
{
  return 30.0f;
}

@end
