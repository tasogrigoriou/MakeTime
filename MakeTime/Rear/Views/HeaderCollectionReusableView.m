//
//  HeaderCollectionReusableView.m
//  MakeTime
//
//  Created by Anastasios Grigoriou on 1/23/17.
//  Copyright © 2017 Grigoriou. All rights reserved.


#import "HeaderCollectionReusableView.h"


@implementation HeaderCollectionReusableView


- (void)awakeFromNib
{
  [super awakeFromNib];
}


// Override initWithFrame: to load our xib file into an array and assign the object (the xib file) to self.
- (id)initWithFrame:(CGRect)frame
{
  self = [super initWithFrame:frame];
  
  if (self) {
    
    // Load our HeaderCollectionReusableView xib file into an array.
    NSArray *arrayOfViews = [[NSBundle mainBundle] loadNibNamed:@"HeaderCollectionReusableView"
                                                          owner:self options:nil];
    
    // If the array is empty, we know something went wrong and we return nil.
    if ([arrayOfViews count] < 1) {
      return nil;
    }
    
    // If the array is not an instance or subclass of UICollectionReusableView, then we also return nil.
    if (![[arrayOfViews objectAtIndex:0] isKindOfClass:[UICollectionReusableView class]]) {
      return nil;
    }
    
    // Grab a reference to the object (the nib) at the 0 index of the array,
    // and assign it to self since self is an instance of UICollectionReusableView.
    self = [arrayOfViews objectAtIndex:0];
  }
  
  return self;
}


@end
