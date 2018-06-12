//
//  CalendarCollectionViewCell.m
//  MakeTime
//
//  Created by Anastasios Grigoriou on 6/8/17.
//  Copyright © 2017 Grigoriou. All rights reserved.
//

#import "CalendarCollectionViewCell.h"
#import "UIColor+RBExtras.h"

@implementation CalendarCollectionViewCell

- (void)awakeFromNib
{
  [super awakeFromNib];
}

// Override initWithFrame: to load our xib file into an array and assign the object (the xib file) to self.
- (id)initWithFrame:(CGRect)frame
{
  if (self = [super initWithFrame:frame]) {
    
    // Load our RearCollectionViewCell xib file into an array.
    NSArray *arrayOfViews = [[NSBundle mainBundle] loadNibNamed:@"CalendarCollectionViewCell" owner:self options:nil];
    
    if ([arrayOfViews count] < 1) {
      return nil;
    }
    if (![[arrayOfViews objectAtIndex:0] isKindOfClass:[UICollectionViewCell class]]) {
      return nil;
    }
    
    // Assign the nib to our instance of CalendarCollectionViewCell
    self = [arrayOfViews objectAtIndex:0];
    
    self.layer.cornerRadius = 3.0f;
    self.layer.borderWidth = 0.5f;
    self.layer.shadowOpacity = 0.5f;
    self.layer.borderColor = [UIColor lightGrayHTMLColor].CGColor;
    self.layer.shadowColor = [UIColor lightGrayHTMLColor].CGColor;
  }
  
  return self;
}

@end
