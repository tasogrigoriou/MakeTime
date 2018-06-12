//
//  CalendarViewMonthCell.h
//  MakeTime
//
//  Created by Anastasios Grigoriou on 2/5/17.
//  Copyright © 2017 Grigoriou. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface CalendarViewMonthCell : UICollectionViewCell

@property (copy, nonatomic) NSDate *displayMonthDate;
@property (copy, nonatomic) NSDate *dateSelected;

@property (strong, nonatomic) UICollectionView *collectionView;

@property (weak, nonatomic) NSArray *events;

@property (weak, nonatomic) id<UICollectionViewDelegate> delegate;

@end
