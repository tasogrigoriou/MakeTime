//
//  CategoriesSelectableViewController.h
//  MakeTime
//
//  Created by Anastasios Grigoriou on 8/3/23.
//  Copyright © 2023 Grigoriou. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CustomViewController.h"
#import "EventKit/EventKit.h"

@class CategoriesSelectableViewController;

@protocol CategoriesSelectableViewControllerDelegate <NSObject>

- (void)didSelectCalendar:(EKCalendar *)calendar;

@end

@interface CategoriesSelectableViewController : CustomViewController

@property (weak, nonatomic) id<CategoriesSelectableViewControllerDelegate> delegate;

- (instancetype)initWithCalendar:(EKCalendar *)calendar delegate:(id<CategoriesSelectableViewControllerDelegate>)delegate;

@end

