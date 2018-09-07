//
//  EventPopUpViewController.h
//  MakeTime
//
//  Created by Anastasios Grigoriou on 8/20/18.
//  Copyright © 2018 Grigoriou. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "EventKit/EventKit.h"

@class EventPopUpViewController;

@protocol EventPopUpDelegate <NSObject>
- (void)didDismissViewController;
@end

@interface EventPopUpViewController : UIViewController

@property (weak, nonatomic) id<EventPopUpDelegate> delegate;

- (instancetype)initWithEvent:(EKEvent *)event delegate:(id<EventPopUpDelegate>)delegate;

@end
