//
//  CustomViewController.h
//  MakeTime
//
//  Created by Anastasios Grigoriou on 1/2/17.
//  Copyright © 2017 Grigoriou. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface CustomViewController : UIViewController

@property (assign, nonatomic) BOOL isAccessToEventStoreGranted;
- (void)updateAuthorizationStatusToAccessEventStore;

@end
