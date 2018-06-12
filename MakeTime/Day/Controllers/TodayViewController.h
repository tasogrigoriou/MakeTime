//
//  TodayViewController.h
//  MakeTime
//
//  Created by Anastasios Grigoriou on 11/27/16.
//  Copyright © 2016 Grigoriou. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CustomViewController.h"

@class TodayCollectionViewDayCell;

@interface TodayViewController : CustomViewController

@property (strong, nonatomic) NSDate *selectedDate;

@property (strong, nonatomic) NSDate *startDateCache;
@property (strong, nonatomic) NSDate *endDateCache;
@property (strong, nonatomic) NSDate *dayDisplayed;

@property (strong, nonatomic) TodayCollectionViewDayCell *currentDayCell;

- (void)setDayDisplayed:(NSDate *)dayDisplayed animated:(BOOL)animated;

@end
