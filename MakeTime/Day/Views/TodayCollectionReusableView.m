//
//  TodayCollectionReusableView.m
//  MakeTime
//
//  Created by Anastasios Grigoriou on 8/2/17.
//  Copyright © 2017 Grigoriou. All rights reserved.
//

#import "TodayCollectionReusableView.h"
#import "UIColor+RBExtras.h"
#import "AppDelegate.h"

@interface TodayCollectionReusableView ()

@end

@implementation TodayCollectionReusableView

- (instancetype)initWithFrame:(CGRect)frame
{
  if (self = [super initWithFrame:frame]) {
    NSArray *arrayOfViews = [[NSBundle mainBundle] loadNibNamed:@"TodayCollectionReusableView"
                                                          owner:self options:nil];
    if ([arrayOfViews count] < 1) {
      return nil;
    }
    if (![[arrayOfViews objectAtIndex:0] isKindOfClass:[UICollectionReusableView class]]) {
      return nil;
    }
    self = [arrayOfViews objectAtIndex:0];
  }
  
  [self drawRoundedCorners];
  
  return self;
}

- (void)drawRoundedCorners
{
  // Draw rounded corners on our TodayCollectionReusableView
  self.layer.cornerRadius = 3.0f;
  self.layer.borderWidth = 0.5f;
  self.layer.shadowOpacity = 0.5f;
  self.layer.borderColor = [UIColor lightGrayHTMLColor].CGColor;
  self.layer.shadowColor = [UIColor lightGrayHTMLColor].CGColor;
}


@end
