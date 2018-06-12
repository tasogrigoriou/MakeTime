//
//  WeekViewController.m
//  MakeTime
//
//  Created by Anastasios Grigoriou on 11/27/16.
//  Copyright © 2016 Grigoriou. All rights reserved.
//

#import "WeekViewController.h"
#import "WeekCollectionViewWeekCell.h"
#import "WeekCollectionViewLayout.h"
#import "SWRevealViewController.h"
#import "TodayViewController.h"
#import "UIColor+RBExtras.h"
#import "Chameleon.h"
#import "CalendarView.h"
#import "CollectionViewFlowLayout.h"
#import "CalendarViewDayCell.h"
#import "CalendarViewWeekCell.h"
#import "AppDelegate.h"
#import "EventKit/EventKit.h"
#import "WeekCollectionViewLayout.h"


@interface WeekViewController () <UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, UIScrollViewDelegate, WeekCollectionViewWeekCellDelegate>

@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;
@property (weak, nonatomic) IBOutlet UILabel *weekLabel;
@property (weak, nonatomic) IBOutlet UIButton *leftButton;
@property (weak, nonatomic) IBOutlet UIButton *rightButton;

@property (strong, nonatomic) NSCalendar *calendar;
@property (strong, nonatomic) NSDateFormatter *dateFormatter;

@property (strong, nonatomic) AppDelegate *appDelegate;
@property (strong, nonatomic) NSArray *customCalendars;
@property (strong, nonatomic) NSArray *customEvents;

@property (assign, nonatomic) NSUInteger cellDisplayedIndex;

@property (strong, nonatomic) NSIndexPath *currentIndexPath;

@property (assign, nonatomic) CGFloat lastContentOffset;

@end


typedef NS_ENUM(NSInteger, ScrollDirection) {
   ScrollDirectionNone,
   ScrollDirectionRight,
   ScrollDirectionLeft,
   ScrollDirectionUp,
   ScrollDirectionDown,
};


@implementation WeekViewController


#pragma mark - View Lifecycle


- (void)viewDidLoad {
   [super viewDidLoad];
   
   [self configureViewAndCollectionView];
   [self calculateStartAndEndDateCaches];
   
   [self.view setNeedsDisplay];
}

- (void)viewDidLayoutSubviews {
   [super viewDidLayoutSubviews];
   
   [self giveGradientBackgroundColor];
}

- (void)viewWillAppear:(BOOL)animated {
   [super viewWillAppear:animated];
   [super updateAuthorizationStatusToAccessEventStore];
   
   // Get rid of line underneath the navigation bar by clipping its bounds to our view controller's view.
   self.navigationController.navigationBar.clipsToBounds = YES;
   
   // Disable swipe when TodayVC appears
   self.revealViewController.panGestureRecognizer.enabled = NO;
}

- (void)viewDidAppear:(BOOL)animated {
   [super viewDidAppear:animated];
   
   [self customizeWeekLabelText]; // TODO - optimize code, DON'T call customizeLabel here!
}

- (void)viewDidDisappear:(BOOL)animated {
   [super viewDidDisappear:animated];
   
   self.selectedDate = nil;
}

- (void)viewWillDisappear:(BOOL)animated {
   [super viewWillDisappear:animated];
   
   // Re-enable swipe when WeekVC disappears
   self.revealViewController.panGestureRecognizer.enabled = YES;
}

- (void)viewWillTransitionToSize:(CGSize)size
       withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
   [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];

   NSLog(@"transition cellDisplayedIndex = %li", self.cellDisplayedIndex);
   [self.collectionView setContentOffset:CGPointMake((self.cellDisplayedIndex + 1) * self.view.bounds.size.height, 0) animated:YES];
   [self.collectionView.collectionViewLayout invalidateLayout];
   [self.collectionView setContentOffset:CGPointMake((self.cellDisplayedIndex) * self.view.bounds.size.height, 0) animated:YES];
   [self customizeWeekLabelText];
   
//   [self updateCollectionViewLayoutWithSize:size];
}

- (void)updateCollectionViewLayoutWithSize:(CGSize)size {
   UICollectionViewFlowLayout *layout = (UICollectionViewFlowLayout *)self.collectionView.collectionViewLayout;
   CGSize itemSizeForPortraitMode = CGSizeMake(self.view.bounds.size.width, 80.0f * 7);
   CGSize itemSizeForLandscapeMode = CGSizeMake(20, 20);
   
   layout.itemSize = (size.width < size.height) ? itemSizeForPortraitMode : itemSizeForLandscapeMode;
   [layout invalidateLayout];
}

- (void)viewWillLayoutSubviews {
   [super viewWillLayoutSubviews];
}


#pragma mark - UICollectionViewDataSource


- (NSInteger)collectionView:(UICollectionView *)collectionView
     numberOfItemsInSection:(NSInteger)section {
   NSInteger numberOfWeekCells = [self.calendar components:NSCalendarUnitWeekOfYear
                                                  fromDate:self.startDateCache
                                                    toDate:self.endDateCache
                                                   options:0].weekOfYear + 1;
   return numberOfWeekCells;
   
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView
                  cellForItemAtIndexPath:(NSIndexPath *)indexPath {
//   [collectionView.collectionViewLayout invalidateLayout];
   
   WeekCollectionViewWeekCell *weekCell = (WeekCollectionViewWeekCell *)[collectionView dequeueReusableCellWithReuseIdentifier:NSStringFromClass([WeekCollectionViewWeekCell class]) forIndexPath:indexPath];
   weekCell.delegate = self;
   
   self.currentIndexPath = indexPath;
   
   NSDateComponents *offsetComponents = [NSDateComponents new];
   offsetComponents.weekOfYear = indexPath.item;
   weekCell.selectedDate = [self.calendar dateByAddingComponents:offsetComponents
                                                         toDate:self.startDateCache
                                                        options:0];
   NSLog(@"weekCell.selectedDate = %@", weekCell.selectedDate);
   
   [weekCell.collectionView reloadData];
   
   return weekCell;
}


#pragma mark - UICollectionViewFlowLayoutDelegate


- (CGSize)collectionView:(UICollectionView *)collectionView
                  layout:(UICollectionViewLayout *)collectionViewLayout
  sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
   return self.collectionView.frame.size;
   
//   if (UIDeviceOrientationIsPortrait([[UIDevice currentDevice] orientation])) {
//      return self.collectionView.frame.size;
//   } else if (UIDeviceOrientationIsLandscape([[UIDevice currentDevice] orientation])) {
//      return CGSizeMake(self.view.frame.size.width, 80.0f * 7);
//   } else {
//      return CGSizeMake(20, 20);
//   }
}


#pragma mark - UIScrollViewDelegate


- (void)scrollViewDidEndScrollingAnimation:(UIScrollView *)scrollView {
   [self scrollViewDidEndDecelerating:(UIScrollView *)self];
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
   NSLog(@"called scrollviewdec");
   
//   [self.collectionView.collectionViewLayout invalidateLayout];

   for (WeekCollectionViewWeekCell *weekCell in [self.collectionView visibleCells]) {
//      [weekCell.collectionView.collectionViewLayout invalidateLayout];
      
      NSLog(@"weekCell.selectedDate = %@", weekCell.selectedDate);
      self.weekLabel.text = [self.dateFormatter stringFromDate:weekCell.selectedDate];
      [[NSUserDefaults standardUserDefaults] setObject:weekCell.selectedDate forKey:@"weekDisplayed"];
   }
}


#pragma mark - IBActions


- (IBAction)leftButtonTouched:(UIButton *)sender {
   [self updateWeekByValue:-1];
}

- (IBAction)rightButtonTouched:(UIButton *)sender {
   [self updateWeekByValue:1];
}

- (void)updateWeekByValue:(NSInteger)value {
   NSDateComponents *valueComponents = [NSDateComponents new];
   valueComponents.weekOfYear = value;
   NSDate *valueDate = [NSDate new];
   
   for (WeekCollectionViewWeekCell *weekCell in [self.collectionView visibleCells]) {
      valueDate = [self.calendar dateByAddingComponents:valueComponents toDate:weekCell.selectedDate options:0];
      [self setWeekDisplayed:valueDate animated:YES];
      weekCell.selectedDate = valueDate;
   }
   
   WeekCollectionViewWeekCell *weekCell = (WeekCollectionViewWeekCell *)[self.collectionView dequeueReusableCellWithReuseIdentifier:NSStringFromClass([WeekCollectionViewWeekCell class]) forIndexPath:self.currentIndexPath];
//   [weekCell.collectionView.collectionViewLayout invalidateLayout];
}


#pragma mark - Private Methods


- (void)customizeWeekLabelText {
   NSDate *currentWeekDisplayed = [[NSUserDefaults standardUserDefaults] objectForKey:@"weekDisplayed"];
   NSNumber *initialScroll = [[NSUserDefaults standardUserDefaults] objectForKey:@"initialScrollDoneForWeek"];
   
   NSDateComponents *comps = [NSDateComponents new];
   comps.day = 1;
   
   if (self.selectedDate) {
      self.weekDisplayed = self.selectedDate;
      
   } else if (currentWeekDisplayed && ![initialScroll boolValue]) {
      self.weekDisplayed = [self.calendar dateByAddingComponents:comps toDate:currentWeekDisplayed options:0];
      
   } else if (currentWeekDisplayed) {
      self.weekDisplayed = currentWeekDisplayed;
      
   } else {
      // add an extra day to account for the UIScrollView offset
      self.weekDisplayed = [self.calendar dateByAddingComponents:comps toDate:[NSDate date] options:0];
   }
   
   self.selectedDate = self.weekDisplayed;
   self.weekLabel.text = [self.dateFormatter stringFromDate:self.weekDisplayed];
   
   [[NSUserDefaults standardUserDefaults] setObject:self.weekDisplayed forKey:@"weekDisplayed"];
   [[NSUserDefaults standardUserDefaults] setObject:@YES forKey:@"initialScrollDoneForWeek"];
}

- (void)giveGradientBackgroundColor {
   // Create an overlay view to give a gradient background color
   CGRect frame = CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height + 2000);
   UIView *overlayView = [[UIView alloc] initWithFrame:frame];
   UIColor *skyBlueLight = [UIColor colorWithHue:0.57 saturation:0.90 brightness:0.98 alpha:1.0];
   overlayView.backgroundColor = [UIColor colorWithGradientStyle:UIGradientStyleTopToBottom
                                                       withFrame:frame
                                                       andColors:@[[UIColor whiteColor], skyBlueLight]];
   [self.view insertSubview:overlayView atIndex:0];
}

- (void)configureViewAndCollectionView {
   self.view.backgroundColor = [UIColor clearColor];
   self.collectionView.backgroundColor = [UIColor clearColor];
   self.automaticallyAdjustsScrollViewInsets = NO;
   
   // IMPORTANT property that requests our dayCell's ONLY when needed for display
   self.collectionView.prefetchingEnabled = NO;
   
   [self.collectionView registerClass:[WeekCollectionViewWeekCell class]
           forCellWithReuseIdentifier:NSStringFromClass([WeekCollectionViewWeekCell class])];
   
   [self.view addSubview:self.collectionView];
}

- (void)calculateStartAndEndDateCaches {
   NSDateComponents *comps = [NSDateComponents new];
   comps.day = -1;
   comps.year = -10;
   self.startDateCache = [self.calendar dateByAddingComponents:comps toDate:[NSDate date] options:0];
   
   comps.year = 10;
   self.endDateCache = [self.calendar dateByAddingComponents:comps toDate:[NSDate date] options:0];
}

- (WeekCollectionViewWeekCell *)currentWeekCell {
   CGFloat weekCellWidth = ((UICollectionViewFlowLayout *)self.collectionView.collectionViewLayout).itemSize.width;
   CGFloat pageNumberRoundedDown = floor(self.collectionView.contentOffset.x / weekCellWidth);
   
   return (WeekCollectionViewWeekCell *)[self.collectionView cellForItemAtIndexPath:[NSIndexPath indexPathForItem:pageNumberRoundedDown inSection:0]];
}

- (NSUInteger)cellDisplayedIndex {
   return (NSUInteger)(self.collectionView.contentOffset.x / self.collectionView.frame.size.width);
}

- (NSDate *)weekDisplayed {
   NSDateComponents *comps = [NSDateComponents new];
   comps.weekOfYear = self.cellDisplayedIndex;
   
   NSDate *week = [self.calendar dateByAddingComponents:comps toDate:self.startDateCache options:0];
   return week;
}

- (void)setWeekDisplayed:(NSDate *)weekDisplayed animated:(BOOL)animated {
   NSDateComponents *differenceComponents = [self.calendar components:NSCalendarUnitWeekOfYear
                                                             fromDate:self.startDateCache
                                                               toDate:weekDisplayed
                                                              options:0];
   if (differenceComponents.weekOfYear != self.cellDisplayedIndex) {
      CGRect rectToScroll = CGRectZero;
      rectToScroll.size = self.collectionView.bounds.size;
      rectToScroll.origin.x = differenceComponents.weekOfYear * self.collectionView.bounds.size.width;
      
      [self.collectionView scrollRectToVisible:rectToScroll animated:animated];
   }
}

- (void)setWeekDisplayed:(NSDate *)weekDisplayed {
   [self setWeekDisplayed:weekDisplayed animated:NO];
}


#pragma mark - Custom Getters


- (NSDateFormatter *)dateFormatter {
   if (!_dateFormatter) {
      _dateFormatter = [NSDateFormatter new];
      _dateFormatter.locale = [NSLocale currentLocale];
      [_dateFormatter setLocalizedDateFormatFromTemplate:@"MMMM, YYYY"];
   }
   return _dateFormatter;
}

- (NSCalendar *)calendar {
   if (!_calendar) {
      _calendar = [NSCalendar currentCalendar];
   }
   return _calendar;
}

- (AppDelegate *)appDelegate {
   if (!_appDelegate) {
      _appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
   }
   return _appDelegate;
}


@end
