//
//  TodayDayView.m
//  MakeTime
//
//  Created by Anastasios Grigoriou on 9/3/18.
//  Copyright © 2018 Grigoriou. All rights reserved.
//

#import "TodayDayView.h"
#import "TodayHourLabelView.h"
#import "MakeTimeCache.h"
#import <QuartzCore/QuartzCore.h>

@implementation TodayDayView

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        NSArray *arrayOfViews = [[NSBundle mainBundle] loadNibNamed:@"TodayDayView"
                                                              owner:self options:nil];
        if ([arrayOfViews count] < 1) {
            return nil;
        }
        if (![[arrayOfViews objectAtIndex:0] isKindOfClass:[UIView class]]) {
            return nil;
        }
        self = [arrayOfViews objectAtIndex:0];
    }
    return self;
}

- (void)initHourLabelsWithCollectionView:(UICollectionView *)collectionView
                             sizeForView:(CGFloat)sizeForView {
    MakeTimeCache *makeTimeCache = [MakeTimeCache sharedManager];
    NSMutableArray *hourViews = [NSMutableArray array];
    NSInteger j = 0;
    for (NSInteger i = 0; i < 24; i++) {
        TodayHourLabelView *hourView = [[TodayHourLabelView alloc] initWithFrame:CGRectZero];
        hourView.backgroundColor = [UIColor clearColor];
        CGRect attributesFrame = CGRectZero;
        attributesFrame.size = CGSizeMake(collectionView.bounds.size.width / 2, sizeForView);
        if (i % 2 == 0) {
            attributesFrame.origin = CGPointMake(0, j * sizeForView);
        } else {
            attributesFrame.origin = CGPointMake(collectionView.bounds.size.width / 2, j * sizeForView);
            j++;
        }
        hourView.frame = attributesFrame;
        hourView.hourLabel.text = makeTimeCache.reusableViewsText[i];
        
        [self addSubview:hourView];
        [hourViews addObject:hourView];
    }
    
    self.hourViews = (NSArray *)hourViews;
}

- (UIImage *)imageWithView:(UIView *)view size:(CGSize)size {
    UIGraphicsBeginImageContextWithOptions(size, NO, 0.0);
    [view.layer renderInContext:UIGraphicsGetCurrentContext()];
    
    UIImage *img = UIGraphicsGetImageFromCurrentImageContext();

    UIGraphicsEndImageContext();
    
    return img;
}

@end
