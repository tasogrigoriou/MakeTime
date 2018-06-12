//
//  CustomViewController.m
//  MakeTime
//
//  Created by Anastasios Grigoriou on 1/2/17.
//  Copyright © 2017 Grigoriou. All rights reserved.
//

#import "CustomViewController.h"
#import "AppDelegate.h"
#import "SWRevealViewController.h"
#import "UIColor+RBExtras.h"
#import "QuartzCore/QuartzCore.h"
#import "CalendarViewController.h"
#import "AddEventViewController.h"

@interface CustomViewController ()

@property (strong, nonatomic) AppDelegate *appDelegate;

@end

@implementation CustomViewController


#pragma mark - View Lifecycle


- (void)viewDidLoad
{
  [super viewDidLoad];
  
  // Get rid of line underneath the navigation bar by clipping its bounds to our view controller's view.
  self.navigationController.navigationBar.clipsToBounds = YES;
  
  self.appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
  
  [self configureBarButtonItems];
}

- (void)viewDidAppear:(BOOL)animated
{
  [super viewDidAppear:animated];
  
  self.navigationController.navigationBar.barTintColor = [UIColor whiteColor];
}

- (void)viewWillAppear:(BOOL)animated
{
  [super viewWillAppear:animated];
  
  [self updateAuthorizationStatusToAccessEventStore];
}

- (void)updateAuthorizationStatusToAccessEventStore
{
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
      [self.appDelegate.eventManager.eventStore requestAccessToEntityType:EKEntityTypeEvent
                                                               completion:^(BOOL granted, NSError *error) {
                                                                 dispatch_async(dispatch_get_main_queue(), ^{
                                                                   weakSelf.isAccessToEventStoreGranted = granted;
                                                                 });
                                                               }];
      break;
    }
  }
}

- (IBAction)revealAdd:(id)sender
{
  CalendarViewController *cvc = [CalendarViewController new];
  [self.navigationController pushViewController:cvc animated:YES];
}

- (void)configureBarButtonItems
{
  // Initialize a SWRevealViewController.
  SWRevealViewController *revealController = [self revealViewController];
  
  // Call the gesture recognizer methods provided by SWRevealViewController on our reveal controller.
  [revealController panGestureRecognizer];
  [revealController tapGestureRecognizer];
  
  UIBarButtonItem *revealBBI = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"menu"]
                                                                style:UIBarButtonItemStylePlain
                                                               target:revealController
                                                               action:@selector(revealToggle:)];
  revealBBI.tintColor = [UIColor blackColor];
  
  UIBarButtonItem *addBBI = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"plus"]
                                                             style:UIBarButtonItemStylePlain
                                                            target:self
                                                            action:@selector(revealAdd:)];
  addBBI.tintColor = [UIColor blackColor];
  
  UIBarButtonItem *watchBBI = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"home"]
                                                               style:UIBarButtonItemStylePlain
                                                              target:revealController
                                                              action:@selector(revealHome:)];
  watchBBI.tintColor = [UIColor blackColor];
  
  // Initialize a flexible space BarButtonItem used to center watchBBI.
  UIBarButtonItem *flexibleSpace =  [[UIBarButtonItem alloc]
                                     initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace
                                     target:nil
                                     action:nil];
  
  // Create array of our buttons and assign them to the left/right of the nav bar.
  //    NSArray *leftButtons = @[revealBBI, flexibleSpace, flexibleSpace, flexibleSpace, watchBBI];
  //    self.navigationItem.leftBarButtonItems = leftButtons;
  //
  //    NSArray *rightButtons = @[addBBI];
  //    self.navigationItem.rightBarButtonItems = rightButtons;
  
  self.navigationItem.leftBarButtonItem = revealBBI;
  self.navigationItem.rightBarButtonItem = addBBI;
}


@end
