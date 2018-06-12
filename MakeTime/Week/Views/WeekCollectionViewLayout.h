//
//  WeekCollectionViewLayout.h
//  MakeTime
//
//  Created by Anastasios Grigoriou on 8/20/17.
//  Copyright © 2017 Grigoriou. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface WeekCollectionViewLayout : UICollectionViewLayout

@end


@protocol WeekCollectionViewLayoutDelegate <NSObject>

- (NSRange)weekViewLayout:(WeekCollectionViewLayout *)layout
timespanForCellAtIndexPath:(NSIndexPath *)indexPath;

- (NSUInteger)weekViewLayout:(WeekCollectionViewLayout *)layout
   weekdayForCellAtIndexPath:(NSIndexPath *)indexPath;

@end
