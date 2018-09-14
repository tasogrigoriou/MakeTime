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

@end
