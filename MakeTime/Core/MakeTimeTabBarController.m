//
//  MakeTimeTabBarController.m
//  MakeTime
//
//  Created by Anastasios Grigoriou on 8/27/18.
//  Copyright © 2018 Grigoriou. All rights reserved.
//

#import "MakeTimeTabBarController.h"
#import "TodayViewController.h"
#import "WeekViewController.h"
#import "MonthViewController.h"
#import "CategoriesViewController.h"

@interface MakeTimeTabBarController ()

@end

@implementation MakeTimeTabBarController

- (instancetype)init {
    self = [super init];
    if (self) {
        [self initViewControllers];
        [self setupTabBarItems];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
//    self.tabBar.opaque = YES;
//    self.tabBar.translucent = YES;
//    self.view.backgroundColor = [UIColor whiteColor];
//    self.tabBar.backgroundColor = [UIColor clearColor];
    
    // SET TAB BAR TRANSPARENT
//    self.tabBar.backgroundColor = [UIColor clearColor];
//    self.tabBar.backgroundImage = [[UIImage alloc] init];
//    self.tabBar.shadowImage = [[UIImage alloc] init];  // removes the border
}

- (void)initViewControllers {
    TodayViewController *todayViewController = [TodayViewController new];
    NSDateComponents *comps = [NSDateComponents new];
    comps.day = 1;
    todayViewController.selectedDate = [[NSCalendar currentCalendar]
                                        dateByAddingComponents:comps toDate:[NSDate date] options:0];
    UINavigationController *todayNavigationController = [[UINavigationController alloc] initWithRootViewController:todayViewController];

    WeekViewController *weekViewController = [WeekViewController new];
    NSDateComponents *comps2 = [NSDateComponents new];
    comps2.weekOfYear = 1;
    weekViewController.selectedDate = [[NSCalendar currentCalendar]
                                       dateByAddingComponents:comps2 toDate:[NSDate date] options:0];
    UINavigationController *weekNavigationController = [[UINavigationController alloc] initWithRootViewController:weekViewController];

    MonthViewController *monthViewController = [MonthViewController new];
    UINavigationController *monthNavigationController = [[UINavigationController alloc] initWithRootViewController:monthViewController];

    CategoriesViewController *categoriesViewController = [CategoriesViewController new];
    UINavigationController *categoriesNavigationController = [[UINavigationController alloc] initWithRootViewController:categoriesViewController];

    self.viewControllers = @[todayNavigationController, weekNavigationController, monthNavigationController, categoriesNavigationController];
}

- (void)setupTabBarItems {
    self.tabBar.items[0].image = [UIImage imageNamed:@"menu.png"];
    self.tabBar.items[0].selectedImage = [UIImage imageNamed:@"menu.png"];
    self.tabBar.items[0].title = @"Day";
    self.tabBar.items[0].tag = 0;
    
    self.tabBar.items[1].image = [UIImage imageNamed:@"menu.png"];
    self.tabBar.items[1].selectedImage = [UIImage imageNamed:@"menu.png"];
    self.tabBar.items[1].title = @"Week";
    self.tabBar.items[1].tag = 1;
    
    self.tabBar.items[2].image = [UIImage imageNamed:@"menu.png"];
    self.tabBar.items[2].selectedImage = [UIImage imageNamed:@"menu.png"];
    self.tabBar.items[2].title = @"Month";
    self.tabBar.items[2].tag = 2;
    
    self.tabBar.items[3].image = [UIImage imageNamed:@"menu.png"];
    self.tabBar.items[3].selectedImage = [UIImage imageNamed:@"menu.png"];
    self.tabBar.items[3].title = @"Categories";
    self.tabBar.items[3].tag = 3;
}

@end
