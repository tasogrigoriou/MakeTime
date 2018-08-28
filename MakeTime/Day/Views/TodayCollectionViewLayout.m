//
//  TodayCollectionViewLayout.m
//  MakeTime
//
//  Created by Anastasios Grigoriou on 4/2/17.
//  Copyright © 2017 Grigoriou. All rights reserved.
//

#import "TodayCollectionViewLayout.h"

static CGFloat const TwoHoursViewHeight = 60.0f;
static CGFloat const TwoHoursViewWidth = 120.0f;

@interface TodayCollectionViewLayout ()

@property (strong, nonatomic) NSMutableArray *cellAttributes;
@property (strong, nonatomic) NSMutableArray *hourAttributes;

@property (assign, nonatomic) CGFloat sizeForSupplementaryView;

@end


@implementation TodayCollectionViewLayout


- (CGSize)collectionViewContentSize {
    if ([self.collectionView.delegate conformsToProtocol:@protocol(TodayCollectionViewLayoutDelegate)]) {
        id <TodayCollectionViewLayoutDelegate> todayCollectionViewLayoutDelegate = (id <TodayCollectionViewLayoutDelegate>)self.collectionView.delegate;
        
        self.sizeForSupplementaryView = [todayCollectionViewLayoutDelegate sizeForSupplementaryView];
    }
    return CGSizeMake(self.collectionView.bounds.size.width, self.sizeForSupplementaryView * 12);
}

/* Calculate every layoutAttributes we will need to use.
 By getting the time of the event and its duration, we are able to compute the frame of every event.
 The supplementary view frames (every single "hour" block) are pretty straightforward too, since their height and width are fixed.
 */
- (void)prepareLayout {
    [self.cellAttributes removeAllObjects];
    [self.hourAttributes removeAllObjects];
    
    // First check to see if TodayVC's conforms to our layout's protocol, and if so, grab a ref to it
    if ([self.collectionView.delegate conformsToProtocol:@protocol(TodayCollectionViewLayoutDelegate)]) {
        id <TodayCollectionViewLayoutDelegate> todayCollectionViewLayoutDelegate = (id <TodayCollectionViewLayoutDelegate>)self.collectionView.delegate;
        
        self.sizeForSupplementaryView = [todayCollectionViewLayoutDelegate sizeForSupplementaryView];
        
        // Compute every TodayCollectionViewCell (EventComponents) layoutAttributes
        for (NSInteger i = 0; i < [self.collectionView numberOfSections]; i++) {
            for (NSInteger j = 0; j < [self.collectionView numberOfItemsInSection:i]; j++) {
                
                NSIndexPath *cellIndexPath = [NSIndexPath indexPathForItem:j inSection:i];
                NSRange timespan = [todayCollectionViewLayoutDelegate calendarViewLayout:self
                                                              timespanForCellAtIndexPath:cellIndexPath];
                NSInteger startingHour = [todayCollectionViewLayoutDelegate calendarViewLayout:self
                                                                    getStartingHourForTimespan:timespan];
                
                CGFloat xpos, width;
                xpos = (timespan.location - startingHour) * (self.collectionView.bounds.size.width / TwoHoursViewWidth);
                width = timespan.length * (self.collectionView.bounds.size.width / TwoHoursViewWidth);
                
                UICollectionViewLayoutAttributes *attributes = [UICollectionViewLayoutAttributes layoutAttributesForCellWithIndexPath:cellIndexPath];
                CGRect attributesFrame = attributes.frame;
                
                NSInteger startPointOfEvent = (timespan.location / TwoHoursViewWidth);
                //            attributesFrame.origin = CGPointMake(xpos, TwoHoursViewHeight * startPointOfEvent);
                attributesFrame.origin = CGPointMake(xpos, self.sizeForSupplementaryView * startPointOfEvent);
                //            attributesFrame.size = CGSizeMake(width, TwoHoursViewHeight);
                attributesFrame.size = CGSizeMake(width, self.sizeForSupplementaryView);
                attributes.frame = attributesFrame;
                
                [self.cellAttributes addObject:attributes];
            }
        }
        
        // Compute every hour block (TodayReusableView) layoutAttributes
        NSInteger j = 0;
        
        for (NSInteger i = 0; i < 24; i++) {
            UICollectionViewLayoutAttributes *attributes = [UICollectionViewLayoutAttributes layoutAttributesForSupplementaryViewOfKind:@"TodayCollectionReusableView" withIndexPath:[NSIndexPath indexPathForItem:i inSection:0]];
            CGRect attributesFrame = CGRectZero;
            //         attributesFrame.size = CGSizeMake(self.collectionView.bounds.size.width / 2, TwoHoursViewHeight);
            attributesFrame.size = CGSizeMake(self.collectionView.bounds.size.width / 2, self.sizeForSupplementaryView);
            if (i % 2 == 0) {
                //            attributesFrame.origin = CGPointMake(0, j * TwoHoursViewHeight);
                attributesFrame.origin = CGPointMake(0, j * self.sizeForSupplementaryView);
            } else {
                //            attributesFrame.origin = CGPointMake(self.collectionView.bounds.size.width / 2, j * TwoHoursViewHeight);
                attributesFrame.origin = CGPointMake(self.collectionView.bounds.size.width / 2, j * self.sizeForSupplementaryView);
                j++;
            }
            attributes.frame = attributesFrame;
            [self.hourAttributes addObject:attributes];
        }
        
    }
}

// Iterates through your previously prepared layoutAttributes and returns all whose frame intersect the provided frame.
- (NSArray<UICollectionViewLayoutAttributes *> *)layoutAttributesForElementsInRect:(CGRect)rect {
    NSMutableArray *allAttributes = [NSMutableArray new];
    
    for (UICollectionViewLayoutAttributes *attributes in self.cellAttributes) {
        if (CGRectIntersectsRect(rect, attributes.frame)) {
            [allAttributes addObject:attributes];
        }
    }
    
    for (UICollectionViewLayoutAttributes *attributes in self.hourAttributes) {
        if (CGRectIntersectsRect(rect, attributes.frame)) {
            [allAttributes addObject:attributes];
        }
    }
    
    return (NSArray *)allAttributes;
}

// Finds and returns the cell's layoutAttributes that match the provided indexPath.
- (UICollectionViewLayoutAttributes *)layoutAttributesForItemAtIndexPath:(NSIndexPath *)indexPath {
    UICollectionViewLayoutAttributes *attributes = nil;
    NSInteger index = [self.cellAttributes indexOfObjectPassingTest:^BOOL(id obj, NSUInteger idx, BOOL *stop) {
        UICollectionViewLayoutAttributes *attributes = obj;
        *stop = [attributes.indexPath isEqual:indexPath];
        return *stop;
    }];
    
    if (index != NSNotFound) {
        attributes = [self.cellAttributes objectAtIndex:index];
    }
    return attributes;
}

// Finds and returns the supplementary view's layoutAttributes that match the provided indexPath.
- (UICollectionViewLayoutAttributes *)layoutAttributesForDecorationViewOfKind:(NSString *)elementKind
                                                                  atIndexPath:(NSIndexPath *)indexPath {
    UICollectionViewLayoutAttributes *attributes = nil;
    NSInteger index = [self.hourAttributes indexOfObjectPassingTest:^BOOL(id obj, NSUInteger idx, BOOL *stop) {
        UICollectionViewLayoutAttributes *attributes = obj;
        *stop = [attributes.indexPath isEqual:indexPath];
        return *stop;
    }];
    
    if (index != NSNotFound) {
        attributes = [self.hourAttributes objectAtIndex:index];
    }
    return attributes;
}


#pragma mark - Custom Getters


- (NSMutableArray *)cellAttributes {
    if (!_cellAttributes) {
        _cellAttributes = [NSMutableArray new];
    }
    return _cellAttributes;
}

- (NSMutableArray *)hourAttributes {
    if (!_hourAttributes) {
        _hourAttributes = [NSMutableArray new];
    }
    return _hourAttributes;
}


@end





















