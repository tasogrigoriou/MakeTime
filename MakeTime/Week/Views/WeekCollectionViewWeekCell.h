//
//  WeekCollectionViewWeekCell.h
//  MakeTime
//
//  Created by Anastasios Grigoriou on 9/14/17.
//  Copyright © 2017 Grigoriou. All rights reserved.
//

#import <UIKit/UIKit.h>

@class WeekCollectionViewWeekCell;
@class EKEvent;

@protocol WeekCollectionViewWeekCellDelegate;


@interface WeekCollectionViewWeekCell : UICollectionViewCell

@property (strong, nonatomic) UICollectionView *collectionView;

@property (strong, nonatomic) NSDate *selectedDate;

@property (strong, nonatomic) NSDate *displayWeekDate;
@property (strong, nonatomic) NSDateComponents *weekComponents;
@property (assign, nonatomic) NSInteger firstWeekdayOfMonthIndex;

@property (assign, nonatomic) NSRange timespan;

@property (weak, nonatomic) id<WeekCollectionViewWeekCellDelegate> delegate;

@end


@protocol WeekCollectionViewWeekCellDelegate <NSObject>

- (void)dayCell:(WeekCollectionViewWeekCell *)cell didSelectEvent:(EKEvent *)event;

@end
