//
//  MakeTimeCache.m
//  MakeTime
//
//  Created by Anastasios Grigoriou on 9/3/18.
//  Copyright © 2018 Grigoriou. All rights reserved.
//

#import "MakeTimeCache.h"
#import "UIKit/UIKit.h"

@implementation MakeTimeCache

+ (id)sharedManager {
    static MakeTimeCache *sharedMyManager = nil;
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
        [self addTextToReusableViews];
        [self initTwoHourIntervalArray];
    }
    return self;
}

- (void)addTextToReusableViews {
    NSDateFormatter *dateFormatter = [NSDateFormatter new];
    dateFormatter.locale = [NSLocale currentLocale];
    [dateFormatter setLocalizedDateFormatFromTemplate:@"h"];
    
    NSDate *startOfDay = [[NSCalendar currentCalendar] dateBySettingHour:0 minute:0 second:0 ofDate:[NSDate date] options:0];
    
    for (NSInteger i = 0; i < 24; i++) {
        NSDate *dateOneHourAhead = [startOfDay dateByAddingTimeInterval:i * 3600];
        NSString *stringFromDate = [dateFormatter stringFromDate:dateOneHourAhead];
        [self.reusableViewsText addObject:stringFromDate];
    }
}

- (void)initTwoHourIntervalArray {
    NSInteger minutes = 0;
    NSMutableArray *twoHourIntervalsInMinutes = [NSMutableArray new];
    for (NSInteger i = 0; i <= 12; i++) {
        [twoHourIntervalsInMinutes addObject:@(minutes)];
        minutes += 120;
    }
    self.twoHourIntervalsInMinutesArray = (NSArray *)twoHourIntervalsInMinutes;
}

@end
