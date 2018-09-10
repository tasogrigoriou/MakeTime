//
//  TodayCollectionViewCell.m
//  MakeTime
//
//  Created by Anastasios Grigoriou on 1/7/17.
//  Copyright © 2017 Grigoriou. All rights reserved.
//

#import "TodayCollectionViewCell.h"
#import "UIColor+RBExtras.h"

@implementation TodayCollectionViewCell


- (void)awakeFromNib
{
  [super awakeFromNib];
}

- (id)initWithFrame:(CGRect)frame
{
  self = [super initWithFrame:frame];
  
  if (self) {
    NSArray *arrayOfViews = [[NSBundle mainBundle] loadNibNamed:@"TodayCollectionViewCell"
                                                          owner:self options:nil];
    if ([arrayOfViews count] < 1) {
      return nil;
    }
    if (![[arrayOfViews objectAtIndex:0] isKindOfClass:[UICollectionViewCell class]]) {
      return nil;
    }
    self = [arrayOfViews objectAtIndex:0];
    
    [self drawRoundedCorners];
    
  }
  
  return self;
}

- (void)drawRoundedCorners {
  self.layer.cornerRadius = 3.0f;
//  self.layer.borderWidth = 0.5f;
//  self.layer.borderColor = [UIColor clearColor].CGColor;

}

- (void)setHighlighted:(BOOL)highlighted
{
   [super setHighlighted:highlighted];
   
   // Set the highlightedTextColor of the label to be white to avoid transparent (clear color) text.
   self.eventLabel.highlightedTextColor = [UIColor whiteColor];
}


@end
