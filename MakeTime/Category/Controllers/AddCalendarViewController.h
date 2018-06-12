//
//  AddCalendarViewController.h
//  MakeTime
//
//  Created by Anastasios Grigoriou on 6/23/17.
//  Copyright © 2017 Grigoriou. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface AddCalendarViewController : UIViewController

@property (assign, nonatomic) NSInteger checkedRow;
@property (assign, nonatomic) NSInteger colorIndex;

@property (strong, nonatomic) NSArray<UIColor *> *calendarUIColors;
@property (strong, nonatomic) NSArray<NSString *> *calendarStringColors;

@end
