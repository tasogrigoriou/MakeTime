//
//  MakeTimeCache.h
//  MakeTime
//
//  Created by Anastasios Grigoriou on 9/3/18.
//  Copyright © 2018 Grigoriou. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "UIKit/UIKit.h"
#import "TodayDayView.h"

@interface MakeTimeCache : NSObject

@property (nonatomic, strong) NSMutableArray<UICollectionReusableView *> *reusableViews;
@property (nonatomic, strong) NSMutableArray<NSString *> *reusableViewsText;
@property (nonatomic, strong) NSArray *twoHourIntervalsInMinutesArray;

@property (nonatomic, strong) NSMutableArray *hourViews;

@property (nonatomic, strong) UIImage *todayDayImage;

+ (id)sharedManager;

@end
