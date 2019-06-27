//
//  RepeatAlertViewController.h
//  MakeTime
//
//  Created by Anastasios Grigoriou on 7/29/17.
//  Copyright © 2017 Grigoriou. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AddEventViewController.h"

@class RepeatAlertViewController;

@protocol RepeatAlertViewControllerDelegate <NSObject>

- (void)didPushRepeatAlertViewController:(BOOL)boolean;

- (void)didSelectRepeatOptions:(NSMutableArray<NSMutableArray *> *)indexPaths;
- (void)didSelectAlarmOption:(NSInteger)index;

@end

@interface RepeatAlertViewController : UIViewController

- (instancetype)initWithIndexPaths:(NSMutableArray<NSMutableArray *> *)indexPaths;

@property (strong, nonatomic) NSString *repeatOrAlarm;
@property (strong, nonatomic) NSIndexPath *checkedIndexPathForRepeat;
@property (assign, nonatomic) NSInteger checkedRowForAlarm;

@property (weak, nonatomic) id<RepeatAlertViewControllerDelegate> delegate;

@end
