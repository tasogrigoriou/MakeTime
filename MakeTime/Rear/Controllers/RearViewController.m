//
//  RearViewController.m
//  MakeTime
//
//  Created by Anastasios Grigoriou on 11/27/16.
//  Copyright © 2016 Grigoriou. All rights reserved.
//

#import "RearViewController.h"
#import "TodayViewController.h"
#import "WeekViewController.h"
#import "MonthViewController.h"
#import "CategoriesViewController.h"
#import "QuartzCore/QuartzCore.h"
#import "UIColor+RBExtras.h"
#import "RearCollectionViewCell.h"
#import "HeaderCollectionReusableView.h"
#import "Chameleon.h"

@interface RearViewController () <UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout>

@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;

@property (strong, nonatomic) NSArray *nestedArray;
@property (strong, nonatomic) NSArray *imagesArray;
@property (strong, nonatomic) NSArray *textsArray;

@end

@implementation RearViewController


#pragma mark - View Lifecycle


- (void)viewDidLoad
{
   [super viewDidLoad];
   
   [self configureViewAndCollectionView];
//   [self giveGradientBackgroundColor];
    self.view.backgroundColor = [UIColor whiteColor];
   
   [self initImagesAndTextsArray];
}


#pragma mark - UICollectionView


- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
   // Return the number of sections needed for our collection view (2, in our case).
   return [self.nestedArray count];
}


- (NSInteger)collectionView:(UICollectionView *)collectionView
     numberOfItemsInSection:(NSInteger)section
{
   // Return the number of items in each section of our imagesArray.
   return [self.imagesArray[section] count];
}


- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView
                  cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
   
   // Provide a new or reusable cell for the collection view,
   // located by the identifier provided in the registerClass:forCellWithReuseIdentifier method declared above.
   RearCollectionViewCell *cell = (RearCollectionViewCell *) [collectionView dequeueReusableCellWithReuseIdentifier:@"RearCell" forIndexPath:indexPath];
   cell.backgroundColor = [UIColor clearColor];
   
   // First retrieve the array by using the section number,
   // and then get the specific items from the array's row.
   cell.cellImage.image = [UIImage imageNamed:[self.imagesArray[indexPath.section] objectAtIndex:indexPath.row]];
   cell.cellLabel.text = [self.textsArray[indexPath.section] objectAtIndex:indexPath.row];
   
   return cell;
}


- (void)collectionView:(UICollectionView *)collectionView
didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
   // Grab a handle to the reveal controller
   // (as if you'd do with a navigation controller via self.navigationController)
//   SWRevealViewController *revealController = self.revealViewController;
   
   // Store a new UIViewController as nil and instantiate it according to if statements.
   UIViewController *newFrontController = nil;
   
   // Instantiate a new view controller depending on which section / row was selected,
   // and init the nil UINavigationController with the new view controller as its root view controller.
   switch (indexPath.section) {
         
      case 0:
         switch (indexPath.row) {
            case 0: {
               TodayViewController *todayViewController = [TodayViewController new];
               NSDateComponents *comps = [NSDateComponents new];
               comps.day = 1;
               todayViewController.selectedDate = [[NSCalendar currentCalendar]
                                                   dateByAddingComponents:comps toDate:[NSDate date] options:0];
               newFrontController = [[UINavigationController alloc] initWithRootViewController:todayViewController];
               break;
            }
            case 1: {
               WeekViewController *weekViewController = [WeekViewController new];
               NSDateComponents *comps = [NSDateComponents new];
               comps.weekOfYear = 1;
               weekViewController.selectedDate = [[NSCalendar currentCalendar]
                                                   dateByAddingComponents:comps toDate:[NSDate date] options:0];
               newFrontController = [[UINavigationController alloc] initWithRootViewController:weekViewController];
               break;
            }
            case 2: {
               MonthViewController *monthViewController = [MonthViewController new];
               newFrontController = [[UINavigationController alloc] initWithRootViewController:monthViewController];
               break;
            }
            case 3: {
               CategoriesViewController *categoriesViewController = [CategoriesViewController new];
               newFrontController = [[UINavigationController alloc] initWithRootViewController:categoriesViewController];
               break;
            }
         }
         
      case 1:
         switch (indexPath.row) {
            case 0: {
               break;
            }
            case 1: {
               break;
            }
         }
   }
   
//   [collectionView performBatchUpdates:^{
//      [revealController setFrontViewController:newFrontController animated:YES];
//      [revealController setFrontViewPosition:FrontViewPositionLeft animated:YES];
//      [collectionView reloadSections:[NSIndexSet indexSetWithIndex:0]];
//   } completion:nil];
   
}

- (void)collectionView:(UICollectionView *)collectionView
didHighlightItemAtIndexPath:(NSIndexPath *)indexPath
{
   RearCollectionViewCell *cell = (RearCollectionViewCell *)[collectionView cellForItemAtIndexPath:indexPath];
   
   // Set background color of cell with animation.
   [UIView animateWithDuration:0.36
                         delay:0
                       options:UIViewAnimationOptionTransitionCrossDissolve
                    animations:^{
                       [cell setBackgroundColor:[UIColor slateGrayHTMLColor]];
                    }
                    completion:nil];
}

- (void)collectionView:(UICollectionView *)collectionView
didUnhighlightItemAtIndexPath:(NSIndexPath *)indexPath
{
   RearCollectionViewCell *cell = (RearCollectionViewCell *)[collectionView cellForItemAtIndexPath:indexPath];
   
   // Revert background color of cell to clear color.
   [UIView animateWithDuration:0.36
                         delay:0
                       options:UIViewAnimationOptionTransitionCrossDissolve
                    animations:^{
                       [cell setBackgroundColor:[UIColor clearColor]];
                    }
                    completion:nil];
}


- (CGSize)collectionView:(UICollectionView *)collectionView
                  layout:(UICollectionViewLayout *)collectionViewLayout
  sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
   return CGSizeMake(collectionView.bounds.size.width - 61.001, collectionView.bounds.size.width / 3.5 - 61.001);
}


- (CGSize)collectionView:(UICollectionView *)collectionView
                  layout:(UICollectionViewLayout *)collectionViewLayout
referenceSizeForHeaderInSection:(NSInteger)section
{
   // Customize size of our header view in the collection view.
   return CGSizeMake(collectionView.bounds.size.width, 1);
}


// Provide our data source a supplementary view which is our custom HeaderCollectionReusableView.
- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView
           viewForSupplementaryElementOfKind:(NSString *)kind
                                 atIndexPath:(NSIndexPath *)indexPath
{
   UICollectionReusableView *reusableView = nil;
   
   if (kind == UICollectionElementKindSectionHeader) {
      
      // Dequeue a reusable supplementary view from our HeaderCollectionReusableView class
      HeaderCollectionReusableView *headerView = [collectionView
                                                  dequeueReusableSupplementaryViewOfKind:UICollectionElementKindSectionHeader
                                                  withReuseIdentifier:@"HeaderReusableView"
                                                  forIndexPath:indexPath];
      
      // Create a horizontal, dark gray line and insert it as a subview of our custom headerView.
      UIView *lineView = [[UIView alloc] initWithFrame:CGRectMake(12, 0, self.view.frame.size.width - 87, 0.30)];
      lineView.backgroundColor = [UIColor lightGrayColor];
      [headerView insertSubview:lineView atIndex:0];
      
      reusableView = headerView;
   }
   
   return reusableView;
}


#pragma mark - Private Methods


- (void)configureViewAndCollectionView
{
   self.view.backgroundColor = [UIColor clearColor];
   self.collectionView.backgroundColor = [UIColor clearColor];
   
   // Hide nav bar on the RearVC.
   [self.navigationController setNavigationBarHidden:YES];
   
   self.automaticallyAdjustsScrollViewInsets = NO;
   
   // Register our custom UICollectionViewCell class with an identifier to use for our collection view.
   [self.collectionView registerClass:[RearCollectionViewCell class] forCellWithReuseIdentifier:@"RearCell"];
   
   // Register custom UICollectionReusableView class with supp. view and identifier located in xib.
   [self.collectionView registerClass:[HeaderCollectionReusableView class] forSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:@"HeaderReusableView"];
}

- (void)giveGradientBackgroundColor
{
   // Create an overlay view to give a gradient background color
   CGRect frame = CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height + 2000);
   UIView *overlayView = [[UIView alloc] initWithFrame:frame];
   UIColor *skyBlueLight = [UIColor colorWithHue:0.57 saturation:0.90 brightness:0.98 alpha:1.0];
   overlayView.backgroundColor = [UIColor colorWithGradientStyle:UIGradientStyleTopToBottom
                                                       withFrame:frame
                                                       andColors:@[[UIColor whiteColor], skyBlueLight]];
   [self.view insertSubview:overlayView atIndex:0];
}

- (void)initImagesAndTextsArray
{
   // Initialize two arrays to split the images into two groups for each section of the collection view.
   NSArray *firstSectionImages = @[@"menu.png", @"watch2.png", @"menu.png", @"watch.png"];
   NSArray *secondSectionImages = @[@"clock.png", @"watch.png"];
   
   // Initialize two arrays to split the texts into two groups for each section of the collection view.
   NSArray *firstSectionTexts = @[@"Today", @"Week", @"Month", @"Calendars"];
   NSArray *secondSectionTexts = @[@"Chart", @"Settings"];
   
   self.imagesArray = @[firstSectionImages, secondSectionImages];
   self.textsArray = @[firstSectionTexts, secondSectionTexts];
   
   self.nestedArray = @[self.imagesArray, self.textsArray];
}


@end
