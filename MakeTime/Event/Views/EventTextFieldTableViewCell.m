//
//  EventTextFieldTableViewCell.m
//  MakeTime
//
//  Created by Anastasios Grigoriou on 7/24/17.
//  Copyright © 2017 Grigoriou. All rights reserved.
//

#import "EventTextFieldTableViewCell.h"

@interface EventTextFieldTableViewCell ()

@end

@implementation EventTextFieldTableViewCell

- (void)awakeFromNib
{
    [super awakeFromNib];
    // Initialization code
}

- (id)initWithFrame:(CGRect)frame
{
  if (self = [super initWithFrame:frame]) {
    
    NSArray *arrayOfViews = [[NSBundle mainBundle] loadNibNamed:@"EventTableViewCell" owner:self options:nil];
    
    if ([arrayOfViews count] < 1) {
      return nil;
    }
    if (![[arrayOfViews objectAtIndex:0] isKindOfClass:[UITableViewCell class]]) {
      return nil;
    }
    
    self = [arrayOfViews objectAtIndex:0];
  }
  
  return self;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
