//
//  UIView+Extras.m
//  MakeTime
//
//  Created by Anastasios Grigoriou on 9/10/18.
//  Copyright © 2018 Grigoriou. All rights reserved.
//

#import "UIView+Extras.h"

@implementation UIView (Extras)

- (void)setHidden:(BOOL)hidden
         duration:(NSTimeInterval)duration
       completion:(void (^)(BOOL finished))completion {
    
    [UIView transitionWithView:self
                      duration:duration
                       options:UIViewAnimationOptionTransitionCrossDissolve
                    animations:^{
                        [self setHidden:hidden];
                    }
                    completion:completion];
}

- (void)setRoundedCorners:(UIRectCorner)corners radius:(CGFloat)radius {
    CGRect rect = self.bounds;
    
    // Create the path
    UIBezierPath *maskPath = [UIBezierPath bezierPathWithRoundedRect:rect byRoundingCorners:corners cornerRadii:CGSizeMake(radius, radius)];
    
    // Create the shape layer and set its path
    CAShapeLayer *maskLayer = [CAShapeLayer layer];
    maskLayer.frame = rect;
    maskLayer.path = maskPath.CGPath;
    
    // Set the newly created shape layer as the mask for the view's layer
    self.layer.mask = maskLayer;
}

@end
