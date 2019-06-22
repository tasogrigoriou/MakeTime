//
//  CustomViewController.m
//  MakeTime
//
//  Created by Anastasios Grigoriou on 1/2/17.
//  Copyright © 2017 Grigoriou. All rights reserved.
//

#import "CustomViewController.h"
#import "AppDelegate.h"
#import "UIColor+RBExtras.h"
#import "QuartzCore/QuartzCore.h"
#import "CalendarViewController.h"
#import "AddEventViewController.h"
#import "EventManager.h"

@interface CustomViewController ()

@property (strong, nonatomic) AppDelegate *appDelegate;

@end

@implementation CustomViewController


#pragma mark - View Lifecycle


- (void)viewDidLoad {
    [super viewDidLoad];
    self.appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    [self configureNavigationItemTitle];
    [self configureBarButtonItems];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    self.navigationController.navigationBar.barTintColor = [UIColor whiteColor];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self updateAuthorizationStatusToAccessEventStore];
}

- (void)configureNavigationItemTitle {
    self.navigationController.navigationBar.clipsToBounds = YES;
    
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectZero];
    label.backgroundColor = [UIColor clearColor];
    label.font = [UIFont fontWithName:@"AvenirNextCondensed-DemiBold" size:21.0f];
    for (UIFont *font in [UIFont fontNamesForFamilyName:@"Avenir Next Condensed"]) {
        NSLog(@"%@", font);
    }
    label.textAlignment = NSTextAlignmentCenter;
    label.textColor = [UIColor blackColor];
    label.text = @"MakeTyme";
    label.layer.shadowRadius = 6.0f;
    label.layer.shadowColor = [UIColor purpleColor].CGColor;
    [label sizeToFit];
    self.navigationItem.titleView = label;
}

- (void)updateAuthorizationStatusToAccessEventStore {
    EKAuthorizationStatus authorizationStatus = [EKEventStore authorizationStatusForEntityType:EKEntityTypeEvent];
    switch (authorizationStatus) {
        case EKAuthorizationStatusDenied: {
        case EKAuthorizationStatusRestricted: {
            self.isAccessToEventStoreGranted = NO;
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Access Denied"
                                                                           message:@"This app doesn't have access to your Calendars. Please allow access in Settings"
                                                                    preferredStyle:UIAlertControllerStyleAlert];
            UIAlertAction *defaultAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault
                                                                  handler:^(UIAlertAction *action) {}];
            [alert addAction:defaultAction];
            [self presentViewController:alert animated:YES completion:nil];
            break;
        }
        }
        case EKAuthorizationStatusAuthorized: {
            self.isAccessToEventStoreGranted = YES;
            [[NSUserDefaults standardUserDefaults] setObject:@(self.isAccessToEventStoreGranted) forKey:@"eventStoreGranted"];
            break;
        }
        case EKAuthorizationStatusNotDetermined: {
            __weak CustomViewController *weakSelf = self;
            [[[EventManager sharedManager] eventStore] requestAccessToEntityType:EKEntityTypeEvent
                                                                      completion:^(BOOL granted, NSError *error) {
                                                                          dispatch_async(dispatch_get_main_queue(), ^{
                                                                              if (granted) {
                                                                                  [[EventManager sharedManager] loadDefaultCalendars];
                                                                              }
                                                                              weakSelf.isAccessToEventStoreGranted = granted;
                                                                          });
                                                                      }];
            break;
        }
    }
}

- (IBAction)revealAdd:(id)sender {
//    [self.navigationController pushViewController:[CalendarViewController new] animated:YES];
//    [self presentViewController:[CalendarViewController new] animated:YES completion:nil];
    
    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:[[AddEventViewController alloc] init]];
    [self presentViewController:navController animated:YES completion:nil];
}

- (void)configureBarButtonItems {
    UIBarButtonItem *addBBI = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"plus"]
                                                               style:UIBarButtonItemStylePlain
                                                              target:self
                                                              action:@selector(revealAdd:)];
    addBBI.tintColor = [UIColor blackColor];
    self.navigationItem.rightBarButtonItem = addBBI;
}


@end
