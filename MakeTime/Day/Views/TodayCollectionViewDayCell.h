//
//  TodayCollectionViewDayCell.h
//  MakeTime
//
//  Created by Anastasios Grigoriou on 8/28/17.
//  Copyright © 2017 Grigoriou. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TodayViewController.h"

@class TodayCollectionViewDayCell;
@class EKEvent;

@protocol TodayCollectionViewDayCellDelegate;


@interface TodayCollectionViewDayCell : UICollectionViewCell

@property (strong, nonatomic) UICollectionView *collectionView;

@property (strong, nonatomic) NSDate *selectedDate;

@property (assign, nonatomic) NSRange timespan;

@property (weak, nonatomic) id<TodayCollectionViewDayCellDelegate> delegate;

- (void)didSetSelectedDate;

@end


@protocol TodayCollectionViewDayCellDelegate <NSObject>

- (void)dayCell:(TodayCollectionViewDayCell *)cell didSelectEvent:(EKEvent *)ekEvent;
- (CGFloat)sizeForSupplementaryView;

@end
