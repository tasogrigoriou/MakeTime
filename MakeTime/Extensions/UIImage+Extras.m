//
//  UIImage+Extras.m
//  MakeTime
//
//  Created by Anastasios Grigoriou on 9/10/18.
//  Copyright © 2018 Grigoriou. All rights reserved.
//

#import "UIImage+Extras.h"

@implementation UIImage (Extras)

+ (UIImage *)imageWithView:(UIView *)view size:(CGSize)size {
    UIGraphicsBeginImageContextWithOptions(size, NO, 0.0);
    [view.layer renderInContext:UIGraphicsGetCurrentContext()];
    
    UIImage *img = UIGraphicsGetImageFromCurrentImageContext();
    
    UIGraphicsEndImageContext();
    
    return img;
}

@end
