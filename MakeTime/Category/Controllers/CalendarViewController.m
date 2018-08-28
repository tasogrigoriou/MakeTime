//
//  CalendarViewController.m
//  MakeTime
//
//  Created by Anastasios Grigoriou on 6/7/17.
//  Copyright © 2017 Grigoriou. All rights reserved.
//

#import "CalendarViewController.h"
#import "AppDelegate.h"
#import "SWRevealViewController.h"
#import "CalendarCollectionViewCell.h"
#import "AddCalendarViewController.h"
#import "AddEventViewController.h"
#import "UIColor+RBExtras.h"
#import "Chameleon.h"
#import "SwipeBack.h"

@interface CalendarViewController () <UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout>

@property (weak, nonatomic) IBOutlet UICollectionView *calendarCollectionView;
@property (weak, nonatomic) IBOutlet UIButton *addCategoryButton;

@property (strong, nonatomic) AppDelegate *appDelegate;

@end


@implementation CalendarViewController 


#pragma mark - View Lifecycle


- (void)viewDidLoad
{
   [super viewDidLoad];
   
   [self configureLabel];
   [self configureButtons];
//   [self giveGradientBackgroundColor];
    self.view.backgroundColor = [UIColor whiteColor];
   [self configureViewAndCollectionView];
   
   // Get a ref to the app delegate and load custom calendars (categories)
   self.appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
   self.customCalendars = [self.appDelegate.eventManager loadCustomCalendars];
}

- (void)viewWillAppear:(BOOL)animated
{
   [super viewWillAppear:animated];
   
   self.navigationController.navigationBar.clipsToBounds = YES;
   self.navigationItem.hidesBackButton = NO;
   
   // Reload the collection view and the custom calendars when navigating back from AddCalendarVC
   self.customCalendars = [self.appDelegate.eventManager loadCustomCalendars];
   [self.calendarCollectionView reloadData];
   
   // disable swipe when view is added to hierarchy
   self.revealViewController.panGestureRecognizer.enabled = NO;
}

- (void)viewWillDisappear:(BOOL)animated
{
   [super viewWillDisappear:animated];
   
   // re-enable swipe when view is removed from hierarchy
   self.revealViewController.panGestureRecognizer.enabled = YES;
}


#pragma mark - Selectors


- (void)popViewController:(id)sender
{
   [self.navigationController popViewControllerAnimated:YES];
}

- (void)addCategory:(id)sender
{
   AddCalendarViewController *addCalendarVC = [AddCalendarViewController new];
   [self.navigationController pushViewController:addCalendarVC animated:YES];
}


#pragma mark - UICollectionViewDataSource


- (NSInteger)collectionView:(UICollectionView *)collectionView
     numberOfItemsInSection:(NSInteger)section
{
   return [self.customCalendars count];
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView
                  cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
   CalendarCollectionViewCell *calendarCell = (CalendarCollectionViewCell *)[collectionView dequeueReusableCellWithReuseIdentifier:@"CalendarCollectionViewCell" forIndexPath:indexPath];
   
   EKCalendar *cal = self.customCalendars[indexPath.item];
   calendarCell.backgroundColor = [UIColor colorWithCGColor:cal.CGColor];
   calendarCell.calendarCellLabel.text = cal.title;
   
   return calendarCell;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
   self.selectedCalendar = self.customCalendars[indexPath.item];
   
   AddEventViewController *addEventVC = [AddEventViewController new];
   addEventVC.indexOfCalendar = indexPath.row;
   [self.navigationController pushViewController:addEventVC animated:YES];
}


#pragma mark - UICollectionViewDelegate


// Override size of CalendarCollectionViewCell
- (CGSize)collectionView:(UICollectionView *)collectionView
                  layout:(UICollectionViewLayout *)collectionViewLayout
  sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
   return CGSizeMake(collectionView.bounds.size.width / 3, collectionView.bounds.size.width / 6);
}

- (void)collectionView:(UICollectionView *)collectionView
didHighlightItemAtIndexPath:(NSIndexPath *)indexPath
{
   CalendarCollectionViewCell *cell = (CalendarCollectionViewCell *)[collectionView cellForItemAtIndexPath:indexPath];
   
   // Set background color of cell with animation
   [UIView animateWithDuration:0.1
                         delay:0
                       options:UIViewAnimationOptionAllowUserInteraction
                    animations:^{
                       cell.backgroundColor = [UIColor clearColor];
                    }
                    completion:nil];
}


- (void)collectionView:(UICollectionView *)collectionView
didUnhighlightItemAtIndexPath:(NSIndexPath *)indexPath
{
   CalendarCollectionViewCell *cell = (CalendarCollectionViewCell *)[collectionView cellForItemAtIndexPath:indexPath];
   
   // Revert background color of cell to original CGColor of the EKCalendar
   [UIView animateWithDuration:0.1
                         delay:0
                       options:UIViewAnimationOptionAllowUserInteraction
                    animations:^{
                       EKCalendar *cal = self.customCalendars[indexPath.row];
                       cell.backgroundColor = [UIColor colorWithCGColor:cal.CGColor];
                    }
                    completion:nil];
}


#pragma mark - Private Methods


- (void)configureLabel
{
   // Customize title on nav bar
   UILabel *label = [[UILabel alloc] initWithFrame:CGRectZero];
   label.backgroundColor = [UIColor clearColor];
   label.font = [UIFont fontWithName:@"Avenir Next Condensed Regular" size:14.0f];
   label.textAlignment = NSTextAlignmentCenter;
   label.textColor = [UIColor blackColor];
   label.text = @"Categories";
   [label sizeToFit];
   self.navigationItem.titleView = label;
}

- (void)configureButtons
{
   self.addCategoryButton.layer.cornerRadius = 1.0f;
   self.addCategoryButton.layer.borderWidth = 0.7f;
   self.addCategoryButton.layer.shadowOpacity = 0.5f;
   self.addCategoryButton.layer.borderColor = [UIColor lightGrayHTMLColor].CGColor;
   self.addCategoryButton.layer.shadowColor = [UIColor lightGrayHTMLColor].CGColor;
   
   // Customize left bar button item
   UIBarButtonItem *leftButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"backarrow2"]
                                                                      style:UIBarButtonItemStylePlain
                                                                     target:self
                                                                     action:@selector(popViewController:)];
   leftButtonItem.tintColor = [UIColor blackColor];
   self.navigationItem.leftBarButtonItem = leftButtonItem;
   self.navigationController.swipeBackEnabled = YES;
}

- (void)giveGradientBackgroundColor
{
   // Create an overlay view to give a gradient background color
   CGRect frame = CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height + 3000);
   UIView *overlayView = [[UIView alloc] initWithFrame:frame];
   UIColor *skyBlueLight = [UIColor colorWithHue:0.57 saturation:0.90 brightness:0.98 alpha:1.0];
   overlayView.backgroundColor = [UIColor colorWithGradientStyle:UIGradientStyleTopToBottom
                                                       withFrame:frame
                                                       andColors:@[[UIColor whiteColor], skyBlueLight]];
   [self.view insertSubview:overlayView atIndex:0];
}

- (void)configureViewAndCollectionView
{
   self.calendarCollectionView.backgroundColor = [UIColor clearColor];
   
   self.automaticallyAdjustsScrollViewInsets = NO;
   
   // Do NOT modify the content area of the scroll view using the safe area insets
   if (@available(iOS 11.0, *)) {
      self.calendarCollectionView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
   }
   
   [self.calendarCollectionView registerClass:[CalendarCollectionViewCell class]
                   forCellWithReuseIdentifier:@"CalendarCollectionViewCell"];
}


@end









