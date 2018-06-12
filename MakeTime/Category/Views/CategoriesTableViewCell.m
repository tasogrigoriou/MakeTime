//
//  CategoriesTableViewCell.m
//  MakeTime
//
//  Created by Anastasios Grigoriou on 6/15/17.
//  Copyright © 2017 Grigoriou. All rights reserved.
//

#import "CategoriesTableViewCell.h"
#import "UIColor+RBExtras.h"

@interface CategoriesTableViewCell ()

@end

@implementation CategoriesTableViewCell

- (void)awakeFromNib
{
  [super awakeFromNib];
}

// Override initWithFrame: to load our xib file into an array and assign the object (the xib file) to self.
- (id)initWithFrame:(CGRect)frame
{
  if (self = [super initWithFrame:frame]) {
    
    // Load our CategoriesTableViewCell xib file into an array.
    NSArray *arrayOfViews = [[NSBundle mainBundle] loadNibNamed:@"CategoriesTableViewCell" owner:self options:nil];
    
    if ([arrayOfViews count] < 1) {
      return nil;
    }
    if (![[arrayOfViews objectAtIndex:0] isKindOfClass:[UITableViewCell class]]) {
      return nil;
    }
    
    // Assign the nib to our instance of CategoriesTableViewCell
    self = [arrayOfViews objectAtIndex:0];
  }
  
  return self;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
  [super setSelected:selected animated:animated];
  // Configure the view for the selected state
}

- (void)setEditing:(BOOL)editing animated:(BOOL)animated
{
  [super setEditing:editing animated:animated];
}

@end
