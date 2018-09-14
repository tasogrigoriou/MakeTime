//
//  WeekDayLineView.m
//  MakeTime
//
//  Created by Anastasios Grigoriou on 9/8/18.
//  Copyright © 2018 Grigoriou. All rights reserved.
//

#import "WeekDayLineView.h"
#import "UIColor+RBExtras.h"

@implementation WeekDayLineView

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        NSArray *arrayOfViews = [[NSBundle mainBundle] loadNibNamed:@"WeekDayLineView"
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

- (void)initWeekdayLinesWithCollectionView:(UICollectionView *)collectionView {
    NSMutableArray *lineViews = [NSMutableArray array];
    for (NSInteger i = 0; i < 7; i++) {
        if (i > 0 && i < 7) {
            UIView *lineView = [[UIView alloc] initWithFrame:CGRectZero];
            lineView.backgroundColor = [UIColor lightGrayHTMLColor];
            
            CGRect attributesFrame = CGRectZero;
            attributesFrame.size = CGSizeMake(0.5, collectionView.bounds.size.height);
            attributesFrame.origin = CGPointMake(i * (collectionView.bounds.size.width / 7), 0);
            
            lineView.frame = attributesFrame;
            
            [self addSubview:lineView];
            [lineViews addObject:lineView];
        }
    }
    
    self.lineViews = (NSArray *)lineViews;
}

@end
