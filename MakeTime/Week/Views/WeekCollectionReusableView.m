//
//  WeekCollectionReusableView.m
//  MakeTime
//
//  Created by Anastasios Grigoriou on 8/20/17.
//  Copyright © 2017 Grigoriou. All rights reserved.
//

#import "WeekCollectionReusableView.h"
#import "UIColor+RBExtras.h"

@implementation WeekCollectionReusableView

- (instancetype)initWithFrame:(CGRect)frame {
   if (self = [super initWithFrame:frame]) {
      NSArray *arrayOfViews = [[NSBundle mainBundle] loadNibNamed:@"WeekCollectionReusableView"
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

- (void)drawRoundedCorners {
   self.layer.cornerRadius = 2.0f;
   self.layer.borderWidth = 0.5f;
   self.layer.shadowOpacity = 0.5f;
   self.layer.borderColor = [UIColor lightGrayHTMLColor].CGColor;
   self.layer.shadowColor = [UIColor lightGrayHTMLColor].CGColor;
}

@end
