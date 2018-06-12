//
//  RearCollectionViewCell.m
//  MakeTime
//
//  Created by Anastasios Grigoriou on 1/8/17.
//  Copyright © 2017 Grigoriou. All rights reserved.
//

#import "RearCollectionViewCell.h"

@implementation RearCollectionViewCell


- (void)awakeFromNib
{
  [super awakeFromNib];
  // Initialization code
}


// Override initWithFrame: to load our xib file into an array and assign the object (the xib file) to self.
- (id)initWithFrame:(CGRect)frame
{
  self = [super initWithFrame:frame];
  
  if (self) {
    
    // Load our RearCollectionViewCell xib file into an array.
    NSArray *arrayOfViews = [[NSBundle mainBundle] loadNibNamed:@"RearCollectionViewCell"
                                                          owner:self options:nil];
    
    // If the array is empty, we know something went wrong and we return nil.
    if ([arrayOfViews count] < 1) {
      return nil;
    }
    
    // If the array is not an instance or subclass of UICollectionViewCell, then we also return nil.
    if (![[arrayOfViews objectAtIndex:0] isKindOfClass:[UICollectionViewCell class]]) {
      return nil;
    }
    
    // Grab a reference to the object (the nib) with the 0 index of the array,
    // and assign it to self since self is an instance of UICollectionViewCell.
    self = [arrayOfViews objectAtIndex:0];
    
    self.layer.cornerRadius = 3.0f;
  }
  
  return self;
}


@end
