//
//  TodayCollectionReusableView.h
//  MakeTime
//
//  Created by Anastasios Grigoriou on 8/2/17.
//  Copyright © 2017 Grigoriou. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "EventKit/EventKit.h"

@interface TodayCollectionReusableView : UICollectionReusableView

@property (weak, nonatomic) IBOutlet UILabel *hourLabel;

@property (strong, nonatomic) EKEvent *event;

@end
