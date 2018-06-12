//
//  UIColor+Converter.m
//  MakeTime
//
//  Created by Anastasios Grigoriou on 7/12/17.
//  Copyright © 2017 Grigoriou. All rights reserved.
//

#import "UIColor+Converter.h"

@implementation UIColor (Converter)

// UIColor extension that converts both colors to the same color space before comparing them.
- (BOOL)isEqualToColor:(UIColor *)otherColor
{
  CGColorSpaceRef colorSpaceRGB = CGColorSpaceCreateDeviceRGB();
  
  UIColor *(^convertColorToRGBSpace)(UIColor *) = ^(UIColor *color) {
    if (CGColorSpaceGetModel(CGColorGetColorSpace(color.CGColor)) == kCGColorSpaceModelMonochrome) {
      const CGFloat *oldComponents = CGColorGetComponents(color.CGColor);
      CGFloat components[4] = {oldComponents[0], oldComponents[0], oldComponents[0], oldComponents[1]};
      CGColorRef colorRef = CGColorCreate(colorSpaceRGB, components);
      
      UIColor *color = [UIColor colorWithCGColor:colorRef];
      CGColorRelease(colorRef);
      return color;
    } else {
      return color;
    }
  };
  
  UIColor *selfColor = convertColorToRGBSpace(self);
  otherColor = convertColorToRGBSpace(otherColor);
  CGColorSpaceRelease(colorSpaceRGB);
  
  return [selfColor isEqual:otherColor];
}

@end
