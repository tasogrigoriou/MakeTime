//
//  CustomAnimationController.m
//  MakeTime
//
//  Created by Anastasios Grigoriou on 5/29/17.
//  Copyright © 2017 Grigoriou. All rights reserved.
//

#import "CustomAnimationController.h"

static double const TRANSITION_DURATION = 0.5;

@implementation CustomAnimationController


- (NSTimeInterval)transitionDuration:(id <UIViewControllerContextTransitioning>)transitionContext
{
  return TRANSITION_DURATION;
}


- (void)animateTransition:(id <UIViewControllerContextTransitioning>)transitionContext
{
  UIViewController *fromViewController = [transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];
  UIViewController *toViewController = [transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];
  
  UIView *fromView = fromViewController.view;
  UIView *toView = toViewController.view;
  
  CGRect initialFromViewFrame = [transitionContext initialFrameForViewController:fromViewController];
  CGRect finalFromViewFrame = initialFromViewFrame;
  finalFromViewFrame.origin.y -= initialFromViewFrame.size.height;
  
  CGRect finalToViewFrame = [transitionContext finalFrameForViewController:toViewController];
  CGRect initialToViewFrame = finalToViewFrame;
  initialToViewFrame.origin.y += finalToViewFrame.size.height;
  
  fromView.frame = initialFromViewFrame;
  toView.frame = initialToViewFrame;
  
  [UIView animateWithDuration:TRANSITION_DURATION
                   animations:^ { fromView.frame = finalFromViewFrame; toView.frame = finalToViewFrame;}
                   completion:^(BOOL finished) { [transitionContext completeTransition:finished]; }];
}


@end

