//
//  CategoriesViewController.h
//  MakeTime
//
//  Created by Anastasios Grigoriou on 6/15/17.
//  Copyright © 2017 Grigoriou. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CustomViewController.h"

@interface CategoriesViewController : CustomViewController

@property (strong, nonatomic) NSArray<NSString *> *calendarStringColors;
@property (strong, nonatomic) NSArray<UIColor *> *calendarUIColors;

@end