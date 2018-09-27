//
//  CategoriesViewController.h
//  MakeTime
//
//  Created by Anastasios Grigoriou on 6/15/17.
//  Copyright © 2017 Grigoriou. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CustomViewController.h"
#import "EventKit/EventKit.h"

@class CategoriesViewController;

@protocol CategoriesViewControllerDelegate <NSObject>

- (void)didSelectCalendar:(EKCalendar *)calendar;

@end

@interface CategoriesViewController : CustomViewController

@property (weak, nonatomic) id<CategoriesViewControllerDelegate> delegate;

- (instancetype)initWithCalendar:(EKCalendar *)calendar delegate:(id<CategoriesViewControllerDelegate>)delegate;

@end
