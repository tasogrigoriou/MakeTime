//
//  MonthCollectionViewFlowLayout.h
//  MakeTime
//
//  Created by Anastasios Grigoriou on 2/5/17.
//  Copyright © 2017 Grigoriou. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CalendarView.h"


@interface CollectionViewFlowLayout : UICollectionViewFlowLayout


- (instancetype)initWithCollectionViewSize:(CGSize)size
                              headerHeight:(CGFloat)headerHeight
                                     scope:(CalendarScope)scope;


@end
