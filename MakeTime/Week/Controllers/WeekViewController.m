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
#import "EventPopUpViewController.h"
#import "EditEventViewController.h"
#import "UIView+Extras.h"


@interface WeekViewController () <UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, UIScrollViewDelegate, WeekCollectionViewWeekCellDelegate, EventPopUpDelegate>

@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;
@property (weak, nonatomic) IBOutlet UILabel *weekLabel;
@property (weak, nonatomic) IBOutlet UIButton *leftButton;
@property (weak, nonatomic) IBOutlet UIButton *rightButton;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicator;

@property (strong, nonatomic) NSCalendar *calendar;
@property (strong, nonatomic) NSDateFormatter *dateFormatter;

@property (strong, nonatomic) AppDelegate *appDelegate;
@property (strong, nonatomic) NSArray *customCalendars;
@property (strong, nonatomic) NSArray *customEvents;

@property (assign, nonatomic) NSUInteger cellDisplayedIndex;
@property (strong, nonatomic) NSIndexPath *currentIndexPath;
@property (assign, nonatomic) CGFloat lastContentOffset;

@property (strong, nonatomic) NSDateComponents *offsetComponents;

@property (nonatomic) BOOL isFirstTimeLoadingView;
@property (nonatomic) BOOL selectedLastViewController;

@property (nonatomic) BOOL orientationChanged;

@property (strong, nonatomic) UIRefreshControl *refreshControl;

@end


typedef NS_ENUM(NSInteger, LoadedWeekCellState) {
    LoadedWeekCellNever,
    LoadedWeekCellOnce,
    LoadedWeekCellTwice,
    LoadedWeekCellMoreThanTwice,
};


@implementation WeekViewController


#pragma mark - View Lifecycle


- (void)viewDidLoad {
    [super viewDidLoad];
    [self configureViewAndCollectionView];
    [self calculateStartAndEndDateCaches];
    
    [self addTabBarNotificationObserver];
    [self addDataDidChangeNotificationObserver];
    [self addOrientationChangeObserver];
    
    [self setupLoadedWeekCellCount];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    if (self.orientationChanged) {
        [self reloadDataAndLayout];
        self.orientationChanged = NO;
    }
}

- (void)setupLoadedWeekCellCount {
    [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithInteger:1] forKey:@"loadedWeekCellCount"];
}

- (void)viewWillTransitionToSize:(CGSize)size
       withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"orientationChanged" object:self userInfo:nil];
    [self reloadDataAndLayout];
}

- (void)reloadDataAndLayout {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self.collectionView layoutIfNeeded];
        [self.collectionView reloadData];
        
        WeekCollectionViewWeekCell *weekCell = (WeekCollectionViewWeekCell *)[self.collectionView dequeueReusableCellWithReuseIdentifier:NSStringFromClass([WeekCollectionViewWeekCell class]) forIndexPath:self.currentIndexPath];
        [weekCell.collectionView layoutIfNeeded];
        [weekCell.collectionView reloadData];
        
        [self setWeekDisplayed:self.selectedDate animated:NO];
    });
}


#pragma mark - UICollectionViewDataSource


- (NSInteger)collectionView:(UICollectionView *)collectionView
     numberOfItemsInSection:(NSInteger)section {
    return [self.calendar components:NSCalendarUnitWeekOfYear
                            fromDate:self.startDateCache
                              toDate:self.endDateCache
                             options:0].weekOfYear + 1;
    
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView
                  cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    WeekCollectionViewWeekCell *weekCell = (WeekCollectionViewWeekCell *)[collectionView dequeueReusableCellWithReuseIdentifier:NSStringFromClass([WeekCollectionViewWeekCell class]) forIndexPath:indexPath];
    weekCell.delegate = self;
    
    self.currentIndexPath = indexPath;
    
    self.offsetComponents.weekOfYear = indexPath.item;
    weekCell.selectedDate = [self.calendar dateByAddingComponents:self.offsetComponents
                                                           toDate:self.startDateCache
                                                          options:0];
    [weekCell didSetSelectedDateWithFrame:self.collectionView.frame];
    [self customizeWeekLabelText];
    
    return weekCell;
}


#pragma mark - UICollectionViewFlowLayoutDelegate


- (CGSize)collectionView:(UICollectionView *)collectionView
                  layout:(UICollectionViewLayout *)collectionViewLayout
  sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    return self.collectionView.frame.size;
}


#pragma mark - WeekCollectionViewWeekCellDelegate


- (void)weekCell:(WeekCollectionViewWeekCell *)cell didSelectEvent:(EKEvent *)ekEvent {
    EventPopUpViewController *eventPopUpVC = [[EventPopUpViewController alloc] initWithEvent:ekEvent delegate:self];
    [self presentViewController:eventPopUpVC animated:YES completion:nil];
}

- (CGFloat)sizeForSupplementaryView {
    return self.collectionView.frame.size.width / 7;
}

- (CGFloat)heightForSupplementaryView {
    if (UIInterfaceOrientationIsPortrait([[UIApplication sharedApplication] statusBarOrientation])) {
        return self.collectionView.frame.size.width / 7;
    } else {
        return 45;
    }
}


#pragma mark - EventPopUpDelegate


- (void)didDismissViewController {
}

- (void)editEventButtonPressedWithEvent:(EKEvent *)event {
    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:[[EditEventViewController alloc] initWithEvent:event]];
    [self presentViewController:navController animated:YES completion:nil];
}


#pragma mark - UIScrollViewDelegate


- (void)scrollViewDidEndScrollingAnimation:(UIScrollView *)scrollView {
    [self scrollViewDidEndDecelerating:(UIScrollView *)self];
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        WeekCollectionViewWeekCell *weekCell = self.collectionView.visibleCells.firstObject;
        self.weekLabel.text = [self.dateFormatter stringFromDate:weekCell.selectedDate];
        self.selectedDate = weekCell.selectedDate;
        [[NSUserDefaults standardUserDefaults] setObject:weekCell.selectedDate forKey:@"weekDisplayed"];
    });
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    if (scrollView.contentOffset.y < -25 && self.activityIndicator.isHidden) {
        self.activityIndicator.hidden = NO;
        [self.activityIndicator startAnimating];
        [[self currentWeekCell].collectionView reloadData];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self.activityIndicator stopAnimating];
            self.activityIndicator.hidden = YES;
        });
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
    
    WeekCollectionViewWeekCell *weekCell = self.collectionView.visibleCells.firstObject;
    NSDate *valueDate = [self.calendar dateByAddingComponents:valueComponents toDate:weekCell.selectedDate options:0];
    [self setWeekDisplayed:valueDate animated:YES];
    weekCell.selectedDate = valueDate;
}


#pragma mark - Private Methods


- (void)customizeWeekLabelText {
    if (self.isFirstTimeLoadingView) {
        NSDate *currentWeekDisplayed = [[NSUserDefaults standardUserDefaults] objectForKey:@"weekDisplayed"];
        NSNumber *initialScroll = [[NSUserDefaults standardUserDefaults] objectForKey:@"initialScrollDoneForWeek"];
        
        NSDateComponents *comps = [NSDateComponents new];
        comps.weekOfYear = 1;
        
        if (self.selectedLastViewController) {
            NSDateComponents *offsetComps = [NSDateComponents new];
            offsetComps.day = 2;
            self.weekDisplayed = [self.calendar dateByAddingComponents:offsetComps toDate:[NSDate date] options:0];
            self.selectedLastViewController = NO;
            
        } else if (self.selectedDate) {
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
        
        NSLog(@"self.selectedDate = %@", self.selectedDate);
        
        self.isFirstTimeLoadingView = NO;
    }
}

- (void)configureViewAndCollectionView {
    self.view.backgroundColor = [UIColor whiteColor];
    self.collectionView.backgroundColor = [UIColor clearColor];
    self.automaticallyAdjustsScrollViewInsets = NO;
    
    [self.collectionView registerClass:[WeekCollectionViewWeekCell class]
            forCellWithReuseIdentifier:NSStringFromClass([WeekCollectionViewWeekCell class])];
    
    [self.view addSubview:self.collectionView];
    
    self.refreshControl = [[UIRefreshControl alloc] init];
    self.refreshControl.tintColor = [UIColor purpleColor];
    [self.refreshControl addTarget:self
                            action:@selector(refreshData)
                  forControlEvents:UIControlEventValueChanged];
//    self.collectionView.refreshControl = self.refreshControl;
    
    self.activityIndicator.hidden = YES;
    
    self.definesPresentationContext = YES;
    self.isFirstTimeLoadingView = YES;
}

- (void)calculateStartAndEndDateCaches {
    NSDateComponents *comps = [NSDateComponents new];
    NSDate *today = [NSDate date];
    comps.day = -1;
    comps.year = -10;
    self.startDateCache = [self.calendar dateByAddingComponents:comps toDate:today options:0];
    
    comps.year = 10;
    self.endDateCache = [self.calendar dateByAddingComponents:comps toDate:today options:0];
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
    [[NSNotificationCenter defaultCenter] postNotificationName:@"hideWeekCell" object:nil];
    
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

- (void)addTabBarNotificationObserver {
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(scrollToToday)
                                                 name:@"didSelectLastSelectedViewController"
                                               object:nil];
}

- (void)scrollToToday {
    NSDateComponents *comps = [NSDateComponents new];
    comps.day = 2;
    [self setWeekDisplayed:[self.calendar dateByAddingComponents:comps toDate:[NSDate date] options:0] animated:YES];
    self.selectedLastViewController = YES;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        self.weekLabel.text = [self.dateFormatter stringFromDate:[self.calendar dateByAddingComponents:comps toDate:[NSDate date] options:0]];
        [[self currentWeekCell].collectionView reloadData];
    });
}

- (void)addDataDidChangeNotificationObserver {
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(dataDidChange)
                                                 name:@"calendarOrEventDataDidChange"
                                               object:nil];
}

- (void)addOrientationChangeObserver {
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(orientationDidChange)
                                                 name:@"orientationChanged"
                                               object:nil];
}

- (void)dataDidChange {
    [self.collectionView reloadData];
}

- (void)orientationDidChange {
    self.orientationChanged = YES;
}

- (void)refreshData {
    [self.collectionView reloadData];
    [self.refreshControl endRefreshing];
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

- (NSDateComponents *)offsetComponents {
    if (!_offsetComponents) {
        _offsetComponents = [NSDateComponents new];
    }
    return _offsetComponents;
}


@end
