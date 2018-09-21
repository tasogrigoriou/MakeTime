//
//  UIView+Extras.h
//  MakeTime
//
//  Created by Anastasios Grigoriou on 9/10/18.
//  Copyright © 2018 Grigoriou. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIView (Extras)

- (void)setHidden:(BOOL)hidden
         duration:(NSTimeInterval)duration
       completion:(void (^)(BOOL finished))completion;

-(void)setRoundedCorners:(UIRectCorner)corners radius:(CGFloat)radius;

@end
