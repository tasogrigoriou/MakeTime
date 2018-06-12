//
//  AppDelegate.h
//  MakeTime
//
//  Created by Anastasios Grigoriou on 11/3/16.
//  Copyright © 2016 Grigoriou. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>
#import "EventManager.h"

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;

@property (strong, nonatomic) EventManager *eventManager;
@property (assign, nonatomic) BOOL isFirstLaunch;

@property (readonly, strong) NSPersistentContainer *persistentContainer;

- (void)saveContext;

@end

