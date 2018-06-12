//
//  CalendarViewDayCell.h
//  MakeTime
//
//  Created by Anastasios Grigoriou on 2/5/17.
//  Copyright © 2017 Grigoriou. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface CalendarViewDayCell : UICollectionViewCell


@property (nonatomic, strong) UIView *selectedMarkView;
@property (nonatomic, strong) UIView *todayMarkView;
@property (nonatomic, strong) UIView *eventsMarksView;

@property (nonatomic, strong) UILabel *label;
@property (nonatomic) BOOL isToday;
@property (nonatomic) BOOL isCurrentMonth;
@property (nonatomic) BOOL isDaySelected;

@property (nonatomic, weak) NSArray *events;

@property (nonatomic, strong) NSDate *date;


@end
