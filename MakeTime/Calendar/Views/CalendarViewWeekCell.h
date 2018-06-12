//
//  CalendarViewWeekCell.h
//  MakeTime
//
//  Created by Anastasios Grigoriou on 3/1/17.
//  Copyright © 2017 Grigoriou. All rights reserved.


#import <UIKit/UIKit.h>


@interface CalendarViewWeekCell : UICollectionViewCell

@property (copy, nonatomic) NSDate *displayWeekDate;
@property (copy, nonatomic) NSDate *dateSelected;

@property (strong, nonatomic) UICollectionView *collectionView;

@property (weak, nonatomic) NSArray *events;

@property (weak, nonatomic) id<UICollectionViewDelegate> delegate;

@end
