//
//  TodayHourLabelView.m
//  MakeTime
//
//  Created by Anastasios Grigoriou on 9/3/18.
//  Copyright © 2018 Grigoriou. All rights reserved.
//

#import "TodayHourLabelView.h"
#import "UIColor+RBExtras.h"

@implementation TodayHourLabelView

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        NSArray *arrayOfViews = [[NSBundle mainBundle] loadNibNamed:@"TodayHourLabelView"
                                                              owner:self options:nil];
        if ([arrayOfViews count] < 1) {
            return nil;
        }
        if (![[arrayOfViews objectAtIndex:0] isKindOfClass:[UIView class]]) {
            return nil;
        }
        self = [arrayOfViews objectAtIndex:0];
        [self drawRoundedCorners];
    }
    
    return self;
}

- (void)drawRoundedCorners {
    self.layer.cornerRadius = 3.0f;
    self.layer.borderWidth = 0.5f;
    self.layer.borderColor = [UIColor lightGrayHTMLColor].CGColor;
}

@end
