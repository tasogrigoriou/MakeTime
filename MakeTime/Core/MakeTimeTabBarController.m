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
#import "CalendarViewController.h"
#import "ToDoListViewController.h"
#import "MakeTime-Swift.h"

@interface MakeTimeTabBarController () <UITabBarControllerDelegate>

@property (nonatomic) NSUInteger lastSelectedIndex;
@property (strong, nonatomic) UIViewController *lastSelectedViewController;

@end

@implementation MakeTimeTabBarController

- (instancetype)init {
    self = [super init];
    if (self) {
        [self commonInit];
        [self initViewControllers];
        [self setupTabBarItems];
    }
    return self;
}

- (void)commonInit {
    self.delegate = self;
    self.lastSelectedIndex = 0;
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


#pragma mark - UITabBarControllerDelegate


- (void)tabBarController:(UITabBarController *)tabBarController didSelectViewController:(UIViewController *)viewController {
    if ([self.lastSelectedViewController isEqual:viewController]) {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"didSelectLastSelectedViewController" object:nil];
    } else {
        self.lastSelectedViewController = viewController;
    }
}


#pragma mark - Private methods


- (void)initViewControllers {
    TodayViewController *todayViewController = [TodayViewController new];
    NSDateComponents *comps = [NSDateComponents new];
    comps.day = 1;
    todayViewController.selectedDate = [[NSCalendar currentCalendar]
                                        dateByAddingComponents:comps toDate:[NSDate date] options:0];
    UINavigationController *todayNavigationController = [[UINavigationController alloc] initWithRootViewController:todayViewController];

    WeekViewController *weekViewController = [WeekViewController new];
    weekViewController.selectedDate = [NSDate date];

    UINavigationController *weekNavigationController = [[UINavigationController alloc] initWithRootViewController:weekViewController];

    MonthViewController *monthViewController = [MonthViewController new];
    UINavigationController *monthNavigationController = [[UINavigationController alloc] initWithRootViewController:monthViewController];

    CategoriesViewController *categoriesViewController = [[CategoriesViewController alloc] init];
    UINavigationController *categoriesNavigationController = [[UINavigationController alloc]
                                                              initWithRootViewController:categoriesViewController];
    
    PieChartViewController *pieChartViewController = [PieChartViewController new];
    UINavigationController *pieChartNavigationController = [[UINavigationController alloc] initWithRootViewController:pieChartViewController];
    
    self.viewControllers = @[todayNavigationController, weekNavigationController, monthNavigationController, categoriesNavigationController, pieChartNavigationController];

    self.selectedViewController = todayNavigationController;
    self.lastSelectedViewController = todayNavigationController;
}

- (void)setupTabBarItems {
    self.tabBar.items[0].image = [UIImage imageNamed:@"dayview"];
    self.tabBar.items[0].selectedImage = [UIImage imageNamed:@"dayview"];
    self.tabBar.items[0].title = @"Day";
    self.tabBar.items[0].tag = 0;
    
    self.tabBar.items[1].image = [UIImage imageNamed:@"week"];
    self.tabBar.items[1].selectedImage = [UIImage imageNamed:@"week"];
    self.tabBar.items[1].title = @"Week";
    self.tabBar.items[1].tag = 1;
    
    self.tabBar.items[2].image = [UIImage imageNamed:@"month"];
    self.tabBar.items[2].selectedImage = [UIImage imageNamed:@"month"];
    self.tabBar.items[2].title = @"Month";
    self.tabBar.items[2].tag = 2;
    
    self.tabBar.items[3].image = [UIImage imageNamed:@"categories"];
    self.tabBar.items[3].selectedImage = [UIImage imageNamed:@"categories"];
    self.tabBar.items[3].title = @"Calendars";
    self.tabBar.items[3].tag = 3;
    
    self.tabBar.items[4].image = [UIImage imageNamed:@"piechart"];
    self.tabBar.items[4].selectedImage = [UIImage imageNamed:@"piechart"];
    self.tabBar.items[4].title = @"Pie Chart";
    self.tabBar.items[4].tag = 4;
}


@end
