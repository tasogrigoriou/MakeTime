//
//  ReusableViewCache.m
//  MakeTime
//
//  Created by Anastasios Grigoriou on 8/30/18.
//  Copyright © 2018 Grigoriou. All rights reserved.
//

#import "ReusableViewCache.h"

@implementation ReusableViewCache

+ (id)sharedManager {
    static ReusableViewCache *sharedMyManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedMyManager = [[self alloc] init];
    });
    return sharedMyManager;
}

- (id)init {
    if (self = [super init]) {
        self.reusableViews = [[NSMutableArray alloc] init];
        self.reusableViewsText = [[NSMutableArray alloc] init];
    }
    return self;
}

@end
