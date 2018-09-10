//
//  CalendarViewController.m
//  MakeTime
//
//  Created by Anastasios Grigoriou on 6/7/17.
//  Copyright © 2017 Grigoriou. All rights reserved.
//

#import "CalendarViewController.h"
#import "AppDelegate.h"
#import "CalendarCollectionViewCell.h"
#import "AddCalendarViewController.h"
#import "AddEventViewController.h"
#import "UIColor+RBExtras.h"
#import "Chameleon.h"
#import "SwipeBack.h"

@interface CalendarViewController () <UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout>

@property (weak, nonatomic) IBOutlet UICollectionView *calendarCollectionView;
@property (strong, nonatomic) AppDelegate *appDelegate;

@end


@implementation CalendarViewController 


#pragma mark - View Lifecycle


- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self configureLabel];
    [self configureButtons];
    [self configureViewAndCollectionView];
}

- (void)loadCalendarData {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        [[EventManager sharedManager] loadCustomCalendars];
        dispatch_async(dispatch_get_main_queue(), ^{
            self.customCalendars = [[EventManager sharedManager] customCalendars];
            [self.calendarCollectionView reloadData];
        });
    });
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    //    self.navigationController.navigationBar.clipsToBounds = YES;
    //    self.navigationItem.hidesBackButton = NO;
    
    // Reload the collection view and the custom calendars when navigating back from AddCalendarVC
    [self loadCalendarData];
}


#pragma mark - Selectors


- (void)dismissViewController:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)addCategory:(id)sender {
    [self.navigationController pushViewController:[AddCalendarViewController new] animated:YES];
}


#pragma mark - UICollectionViewDataSource


- (NSInteger)collectionView:(UICollectionView *)collectionView
     numberOfItemsInSection:(NSInteger)section {
    return [self.customCalendars count];
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView
                  cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    CalendarCollectionViewCell *calendarCell = (CalendarCollectionViewCell *)[collectionView dequeueReusableCellWithReuseIdentifier:@"CalendarCollectionViewCell" forIndexPath:indexPath];
    
    EKCalendar *cal = self.customCalendars[indexPath.item];
    calendarCell.backgroundColor = [UIColor colorWithCGColor:cal.CGColor];
    calendarCell.calendarCellLabel.text = cal.title;
    
    return calendarCell;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    self.selectedCalendar = self.customCalendars[indexPath.item];
    
    AddEventViewController *addEventVC = [[AddEventViewController alloc] initWithCalendar:self.selectedCalendar];
    addEventVC.indexOfCalendar = indexPath.item;
    [self.navigationController pushViewController:addEventVC animated:YES];
}


#pragma mark - UICollectionViewDelegate


// Override size of CalendarCollectionViewCell
- (CGSize)collectionView:(UICollectionView *)collectionView
                  layout:(UICollectionViewLayout *)collectionViewLayout
  sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    return CGSizeMake(collectionView.bounds.size.width / 3, collectionView.bounds.size.width / 6);
}

- (void)collectionView:(UICollectionView *)collectionView
didHighlightItemAtIndexPath:(NSIndexPath *)indexPath {
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
didUnhighlightItemAtIndexPath:(NSIndexPath *)indexPath {
    CalendarCollectionViewCell *cell = (CalendarCollectionViewCell *)[collectionView cellForItemAtIndexPath:indexPath];
    
    // Revert background color of cell to original CGColor of the EKCalendar
    [UIView animateWithDuration:0.1
                          delay:0
                        options:UIViewAnimationOptionAllowUserInteraction
                     animations:^{
                         EKCalendar *cal = self.customCalendars[indexPath.item];
                         cell.backgroundColor = [UIColor colorWithCGColor:cal.CGColor];
                     }
                     completion:nil];
}


#pragma mark - Private Methods


- (void)configureLabel {
    // Customize title on nav bar
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectZero];
    label.backgroundColor = [UIColor clearColor];
    label.font = [UIFont fontWithName:@"AvenirNextCondensed-DemiBold" size:20.0f];
    label.textAlignment = NSTextAlignmentCenter;
    label.textColor = [UIColor blackColor];
    label.text = @"Categories";
    [label sizeToFit];
    self.navigationItem.titleView = label;
}

- (void)configureButtons {
    NSDictionary *textAttributes = @{ NSFontAttributeName : [UIFont fontWithName:@"AvenirNextCondensed-Regular" size:14.0], NSForegroundColorAttributeName : [UIColor blackColor] };
    UIBarButtonItem *leftButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Cancel"
                                                                       style:UIBarButtonItemStylePlain
                                                                      target:self
                                                                      action:@selector(dismissViewController:)];
    leftButtonItem.tintColor = [UIColor blackColor];
    [leftButtonItem setTitleTextAttributes:textAttributes forState:UIControlStateNormal];
    [leftButtonItem setTitleTextAttributes:textAttributes forState:UIControlStateHighlighted];
    self.navigationItem.leftBarButtonItem = leftButtonItem;
    
    UIBarButtonItem *rightButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Add"
                                                                        style:UIBarButtonItemStylePlain
                                                                       target:self
                                                                       action:@selector(addCategory:)];
    rightButtonItem.tintColor = [UIColor blackColor];
    [rightButtonItem setTitleTextAttributes:textAttributes forState:UIControlStateNormal];
    [rightButtonItem setTitleTextAttributes:textAttributes forState:UIControlStateHighlighted];
    self.navigationItem.rightBarButtonItem = rightButtonItem;
}

- (void)configureViewAndCollectionView {
    self.view.backgroundColor = [UIColor whiteColor];
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









