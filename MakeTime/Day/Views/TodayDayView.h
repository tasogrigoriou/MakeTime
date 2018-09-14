//
//  TodayDayView.h
//  MakeTime
//
//  Created by Anastasios Grigoriou on 9/3/18.
//  Copyright © 2018 Grigoriou. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TodayHourLabelView.h"

@interface TodayDayView : UIView

@property (strong, nonatomic) NSArray<TodayHourLabelView *> *hourViews;

- (void)initHourLabelsWithCollectionView:(UICollectionView *)collectionView
                             sizeForView:(CGFloat)sizeForView;

@end
