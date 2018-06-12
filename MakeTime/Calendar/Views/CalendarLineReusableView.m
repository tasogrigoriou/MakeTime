//
//  CalendarLineReusableView.m
//  MakeTime
//
//  Created by Anastasios Grigoriou on 2/5/17.
//  Copyright © 2017 Grigoriou. All rights reserved.
//

#import "CalendarLineReusableView.h"


@implementation CalendarLineReusableView


- (void)applyLayoutAttributes:(UICollectionViewLayoutAttributes *)layoutAttributes
{
  [super applyLayoutAttributes:layoutAttributes];
  
  
  /*** comment this out if you want no line between each row ***/
  
  // Apply a gray line underneath each row in the collection view.
  //self.backgroundColor = [UIColor colorWithWhite:0.8 alpha:1.0];
}


@end
