//
//  WeekCollectionViewLayout.m
//  MakeTime
//
//  Created by Anastasios Grigoriou on 8/20/17.
//  Copyright © 2017 Grigoriou. All rights reserved.
//

#import "WeekCollectionViewLayout.h"

static const CGFloat DAY_VIEW_HEIGHT = 80.0f;
static const CGFloat DAY_VIEW_WIDTH = 80.0f;
static const CGFloat TWENTY_FOUR_HOURS_WIDTH = 24.0f * 60.0f; // hours in a day represented as a float value

@interface WeekCollectionViewLayout ()

@property (strong, nonatomic) NSMutableArray *cellAttributes;
@property (strong, nonatomic) NSMutableArray *dayAttributes;

@end


@implementation WeekCollectionViewLayout


- (CGSize)collectionViewContentSize {
   return CGSizeMake(self.collectionView.bounds.size.width, DAY_VIEW_HEIGHT * 7);
}

- (BOOL)shouldInvalidateLayoutForBoundsChange:(CGRect)newBounds {
   return YES;
}

- (void)prepareLayout {
   [self.cellAttributes removeAllObjects];
   [self.dayAttributes removeAllObjects];
   
   if ([self.collectionView.delegate conformsToProtocol:@protocol(WeekCollectionViewLayoutDelegate)]) {
      id <WeekCollectionViewLayoutDelegate> weekCollectionViewLayoutDelegate = (id <WeekCollectionViewLayoutDelegate>)self.collectionView.delegate;
      
      // Compute every WeekCollectionViewCell layoutAttributes
      for (NSInteger i = 0; i < [self.collectionView numberOfSections]; i++) {
         for (NSInteger j = 0; j < [self.collectionView numberOfItemsInSection:i]; j++) {
            
            NSIndexPath *cellIndexPath = [NSIndexPath indexPathForItem:j inSection:i];
            NSRange timespan = [weekCollectionViewLayoutDelegate weekViewLayout:self
                                                     timespanForCellAtIndexPath:cellIndexPath];
         
            CGFloat xpos, width;
            xpos = DAY_VIEW_WIDTH + ((timespan.location) * ((self.collectionView.bounds.size.width - DAY_VIEW_WIDTH) / TWENTY_FOUR_HOURS_WIDTH));
            width = timespan.length * ((self.collectionView.bounds.size.width - DAY_VIEW_WIDTH) / TWENTY_FOUR_HOURS_WIDTH);
            
            UICollectionViewLayoutAttributes *attributes = [UICollectionViewLayoutAttributes layoutAttributesForCellWithIndexPath:cellIndexPath];
            CGRect attributesFrame = attributes.frame;
            
            // Get height based on weekday (i.e. Sunday = 1, Saturday = 7...)
            NSUInteger weekday = [weekCollectionViewLayoutDelegate weekViewLayout:self
                                                        weekdayForCellAtIndexPath:cellIndexPath];
            
            attributesFrame.origin = CGPointMake(xpos, (weekday - 1) * DAY_VIEW_HEIGHT);
            attributesFrame.size = CGSizeMake(width, DAY_VIEW_HEIGHT);
            attributes.frame = attributesFrame;
            
            [self.cellAttributes addObject:attributes];
         }
      }
      
      // Compute every WeekCollectionReusableView layoutAttributes
      for (NSInteger i = 0; i < 7; i++) {
         UICollectionViewLayoutAttributes *attributes = [UICollectionViewLayoutAttributes layoutAttributesForSupplementaryViewOfKind:@"WeekCollectionReusableView" withIndexPath:[NSIndexPath indexPathForItem:i inSection:0]];
         
         CGRect attributesFrame = CGRectZero;
         attributesFrame.size = CGSizeMake(DAY_VIEW_WIDTH, DAY_VIEW_HEIGHT);
         attributesFrame.origin = CGPointMake(0, i * DAY_VIEW_HEIGHT);
         
         attributes.frame = attributesFrame;
         [self.dayAttributes addObject:attributes];
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
   
   for (UICollectionViewLayoutAttributes *attributes in self.dayAttributes) {
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
   NSInteger index = [self.dayAttributes indexOfObjectPassingTest:^BOOL(id obj, NSUInteger idx, BOOL *stop) {
      UICollectionViewLayoutAttributes *attributes = obj;
      *stop = [attributes.indexPath isEqual:indexPath];
      return *stop;
   }];
   
   if (index != NSNotFound) {
      attributes = [self.dayAttributes objectAtIndex:index];
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

- (NSMutableArray *)dayAttributes {
   if (!_dayAttributes) {
      _dayAttributes = [NSMutableArray new];
   }
   return _dayAttributes;
}


@end
