//
//  WeekCollectionViewCell.m
//  MakeTime
//
//  Created by Anastasios Grigoriou on 8/20/17.
//  Copyright © 2017 Grigoriou. All rights reserved.
//

#import "WeekCollectionViewCell.h"

@implementation WeekCollectionViewCell

- (void)awakeFromNib
{
   [super awakeFromNib];
}

- (id)initWithFrame:(CGRect)frame
{
   self = [super initWithFrame:frame];
   
   if (self) {
      NSArray *arrayOfViews = [[NSBundle mainBundle] loadNibNamed:@"WeekCollectionViewCell"
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

- (void)drawRoundedCorners
{
   self.layer.cornerRadius = 3.0f;
//   self.layer.borderWidth = 0.5f;
//   self.layer.borderColor = [UIColor clearColor].CGColor;
}

@end
