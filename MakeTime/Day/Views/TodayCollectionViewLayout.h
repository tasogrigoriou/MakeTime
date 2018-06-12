//
//  TodayCollectionViewLayout.h
//  MakeTime
//
//  Created by Anastasios Grigoriou on 4/2/17.
//  Copyright © 2017 Grigoriou. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "EventKit/EventKit.h"


@interface TodayCollectionViewLayout : UICollectionViewLayout

@end


@protocol TodayCollectionViewLayoutDelegate <NSObject>

- (NSRange)calendarViewLayout:(TodayCollectionViewLayout *)layout
   timespanForCellAtIndexPath:(NSIndexPath *)indexPath;

- (NSInteger)calendarViewLayout:(TodayCollectionViewLayout *)layout
     getStartingHourForTimespan:(NSRange)timespan;

@end
