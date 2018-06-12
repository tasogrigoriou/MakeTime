//
//  MonthCollectionViewFlowLayout.m
//  MakeTime
//
//  Created by Anastasios Grigoriou on 2/5/17.
//  Copyright © 2017 Grigoriou. All rights reserved.
//

#import "CollectionViewFlowLayout.h"
#import "CalendarLineReusableView.h"


@implementation CollectionViewFlowLayout


// Make this our designated initializer for our monthFlowLayout object for use in CalendarViewMonthCell.
- (instancetype)initWithCollectionViewSize:(CGSize)size
                              headerHeight:(CGFloat)headerHeight
                                     scope:(CalendarScope)scope
{
  if (self = [super init]) {
    
    switch (scope) {
      case CalendarScopeMonth: {
        self.itemSize = CGSizeMake(floor(size.width / 7.0f), (size.height - headerHeight) / 6.0f);
        break;
      }
      case CalendarScopeWeek: {
        self.itemSize = CGSizeMake(floor(size.width / 7.0f), (size.height - headerHeight));
        break;
      }
    }
    
    self.scrollDirection = UICollectionViewScrollDirectionVertical;
    self.minimumLineSpacing = 0.0f;
    self.minimumInteritemSpacing = 0.0f;
    self.sectionInset = UIEdgeInsetsZero;
    
    self.headerReferenceSize = CGSizeMake(size.width, headerHeight);
    self.footerReferenceSize = CGSizeZero;
    
    // Register our decoration view for use in our collection view.
    [self registerClass:[CalendarLineReusableView class]
forDecorationViewOfKind:NSStringFromClass([CalendarLineReusableView class])];
    
  }
  
  return self;
}


// Customize (layout) attributes for the cells and views in our monthFlowLayout in CalendarViewMonthCell.
/*- (NSArray<UICollectionViewLayoutAttributes *> *)layoutAttributesForElementsInRect:(CGRect)rect
 {
 
 // Copy our layoutAttributes into a mutable array.
 NSMutableArray *layoutAttributesMutableArray = [super layoutAttributesForElementsInRect:rect].mutableCopy;
 
 NSMutableArray *decorationLayoutAttributesMutableArray = @[].mutableCopy;
 
 
 // The applyLayoutAttributes method will use the section and index to calculate the page and the position of the cell respectively.
 // The base offset multiplying the section number by the size of the collection view bounds.
 for (UICollectionViewLayoutAttributes *layoutAttributes in layoutAttributesMutableArray) {
 
 // If we are about to go to a new row in our collection view...
 if (layoutAttributes.indexPath.row % 7 == 0) {
 
 // Return the layouts from our CalendarLineReusableView and add it to our layoutAttributesMutableArray
 UICollectionViewLayoutAttributes *decorationLayoutAttributes =
 [self layoutAttributesForDecorationViewOfKind:NSStringFromClass([CalendarLineReusableView class])
 atIndexPath:layoutAttributes.indexPath];
 
 // Store the decorationLayoutAttributes into our mutable array
 [decorationLayoutAttributesMutableArray addObject:decorationLayoutAttributes];
 }
 
 }
 
 // Combine arrays
 [layoutAttributesMutableArray addObjectsFromArray:decorationLayoutAttributesMutableArray];
 
 return layoutAttributesMutableArray;
 }
 
 
 - (UICollectionViewLayoutAttributes *)layoutAttributesForDecorationViewOfKind:(NSString *)decorationViewKind
 atIndexPath:(NSIndexPath *)indexPath
 {
 // Layout attribute information of our decorative view (CalendarLineReusableView)
 UICollectionViewLayoutAttributes *layoutAttributes = [UICollectionViewLayoutAttributes layoutAttributesForDecorationViewOfKind:decorationViewKind withIndexPath:indexPath];
 
 NSInteger rowIndex = indexPath.item / 7;
 
 CGFloat bottomOfCell = self.headerReferenceSize.height + self.itemSize.height - 1.0;
 
 CGFloat yPosition = (rowIndex * self.itemSize.height) + bottomOfCell;
 
 
 layoutAttributes.frame = CGRectIntegral( CGRectMake(0.0, yPosition, self.collectionView.frame.size.width, rowIndex == 2 ? 2.0 : 1.0) ); // if rowIndex is 2 (indexPath.item = 14), set the height frame to 2,
 // otherwise set to 1.
 
 return layoutAttributes;
 }*/



@end
