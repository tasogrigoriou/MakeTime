//
//  WeekViewController.h
//  MakeTime
//
//  Created by Anastasios Grigoriou on 11/27/16.
//  Copyright © 2016 Grigoriou. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CustomViewController.h"

@class WeekCollectionViewWeekCell;

@interface WeekViewController : CustomViewController

@property (strong, nonatomic) NSDate *selectedDate;

@property (strong, nonatomic) NSDate *startDateCache;
@property (strong, nonatomic) NSDate *endDateCache;
@property (strong, nonatomic) NSDate *weekDisplayed;

@property (strong, nonatomic) WeekCollectionViewWeekCell *currentWeekCell;

- (void)setWeekDisplayed:(NSDate *)weekDisplayed animated:(BOOL)animated;

@end
