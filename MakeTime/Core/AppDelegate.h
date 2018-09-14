//
//  AppDelegate.h
//  MakeTime
//
//  Created by Anastasios Grigoriou on 11/3/16.
//  Copyright © 2016 Grigoriou. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "EventManager.h"

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;

@property (assign, nonatomic) BOOL isFirstLaunch;

@end

