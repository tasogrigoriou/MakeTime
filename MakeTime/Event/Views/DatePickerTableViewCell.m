//
//  DatePickerTableViewCell.m
//  MakeTime
//
//  Created by Anastasios Grigoriou on 7/17/17.
//  Copyright © 2017 Grigoriou. All rights reserved.
//

#import "DatePickerTableViewCell.h"
#import "AddEventViewController.h"

@implementation DatePickerTableViewCell

- (void)awakeFromNib
{
  [super awakeFromNib];
}

- (id)initWithFrame:(CGRect)frame
{
  if (self = [super initWithFrame:frame]) {
    
    NSArray *arrayOfViews = [[NSBundle mainBundle] loadNibNamed:@"DatePickerTableViewCell" owner:self options:nil];
    
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

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
