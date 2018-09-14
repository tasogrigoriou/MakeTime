//
//  WeekDayLineView.h
//  MakeTime
//
//  Created by Anastasios Grigoriou on 9/8/18.
//  Copyright © 2018 Grigoriou. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface WeekDayLineView : UIView

@property (strong, nonatomic) NSArray<UIView *> *lineViews;

- (void)initWeekdayLinesWithCollectionView:(UICollectionView *)collectionView;

@end
