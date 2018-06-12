//
//  UIColor+Converter.h
//  MakeTime
//
//  Created by Anastasios Grigoriou on 7/12/17.
//  Copyright © 2017 Grigoriou. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIColor (Converter)

// UIColor extension that converts both colors to the same color space before comparing them.
- (BOOL)isEqualToColor:(UIColor *)otherColor;

@end
