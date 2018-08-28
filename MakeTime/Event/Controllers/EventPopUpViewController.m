//
//  EventPopUpViewController.m
//  MakeTime
//
//  Created by Anastasios Grigoriou on 8/20/18.
//  Copyright © 2018 Grigoriou. All rights reserved.
//

#import "EventPopUpViewController.h"

@interface EventPopUpViewController ()

@end

@implementation EventPopUpViewController

- (instancetype)initWithStyle {
    self = [super initWithNibName:nil bundle:nil];
    
    if (self) {
        self.modalPresentationStyle = UIModalPresentationOverCurrentContext;
        self.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
        
    }
    
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
}

@end
