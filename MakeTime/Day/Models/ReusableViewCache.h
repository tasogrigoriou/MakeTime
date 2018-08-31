//
//  ReusableViewCache.h
//  MakeTime
//
//  Created by Anastasios Grigoriou on 8/30/18.
//  Copyright © 2018 Grigoriou. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "UIKit/UIKit.h"

@interface ReusableViewCache : NSObject

@property (nonatomic, strong) NSMutableArray<UICollectionReusableView *> *reusableViews;
@property (nonatomic, strong) NSMutableArray<NSString *> *reusableViewsText;

+ (id)sharedManager;

@end
