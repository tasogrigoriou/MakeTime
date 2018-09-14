//
//  TodayViewController.m
//  MakeTime
//
//  Created by Anastasios Grigoriou on 11/27/16.
//  Copyright © 2016 Grigoriou. All rights reserved.
//

#import "TodayViewController.h"
#import "TodayCollectionViewLayout.h"
#import "TodayCollectionReusableView.h"
#import "UIColor+RBExtras.h"
#import "Chameleon.h"
#import "QuartzCore/QuartzCore.h"
#import "TodayCollectionViewCell.h"
#import "WeekViewController.h"
#import "CalendarView.h"
#import "EventManager.h"
#import "AppDelegate.h"
#import "AddEventViewController.h"
#import "EventComponents.h"
#import "TodayCollectionViewDayCell.h"
#import "EditEventViewController.h"
#import "EventPopUpViewController.h"
#import "TodayDayView.h"
#import "UIView+Extras.h"

@interface TodayViewController () <UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDataSourcePrefetching, UICollectionViewDelegateFlowLayout, UIScrollViewDelegate, TodayCollectionViewDayCellDelegate, EventPopUpDelegate>

@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;
@property (weak, nonatomic) IBOutlet UILabel *todayLabel;
@property (weak, nonatomic) IBOutlet UIButton *leftButton;
@property (weak, nonatomic) IBOutlet UIButton *rightButton;

@property (assign, nonatomic) BOOL isAccessToEventStoreGranted;

@property (strong, nonatomic) NSCalendar *calendar;
@property (strong, nonatomic) NSDateFormatter *dateFormatter;

@property (strong, nonatomic) AppDelegate *appDelegate;
@property (strong, nonatomic) NSArray *customCalendars;
@property (strong, nonatomic) NSArray *customEvents;

@property (strong, nonatomic) NSArray *twoHourIntervalsInMinutesArray;
@property (assign, nonatomic) NSInteger numberOfEventCarryOvers;

@property (strong, nonatomic) NSArray *eventComponentsArray;
@property (strong, nonatomic) NSArray *convertedEventComponentsArray;
@property (strong, nonatomic) NSArray<NSDate *> *everyTwoHourDateArray;

@property (assign, nonatomic) NSUInteger cellDisplayedIndex;
@property (strong, nonatomic) NSIndexPath *currentIndexPath;

@property (strong, nonatomic) NSDateComponents *dayComponents;

@property (nonatomic) BOOL isFirstTimeLoadingView;
@property (nonatomic) BOOL selectedLastViewController;

@end


@implementation TodayViewController


#pragma mark - View Lifecycle


- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self configureViewAndCollectionView];
    [self calculateStartAndEndDateCaches];
    
    [self addTabBarNotificationObserver];
    [self addDataDidChangeNotificationObserver];
    
    [self setupLoadedDayCellCount];
}

- (void)setupLoadedDayCellCount {
    [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithInteger:1] forKey:@"loadedDayCellCount"];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [super updateAuthorizationStatusToAccessEventStore];
}

- (void)viewWillTransitionToSize:(CGSize)size
       withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
//    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{;
//        [self setDayDisplayed:self.selectedDate animated:NO];
//    });
//    [((UICollectionViewFlowLayout *)self.collectionView.collectionViewLayout) invalidateLayout];

    //    NSLog(@"self.currentIndexPath = %li", self.currentIndexPath.item);
//    TodayCollectionViewDayCell *dayCell = (TodayCollectionViewDayCell *)[self.collectionView dequeueReusableCellWithReuseIdentifier:NSStringFromClass([TodayCollectionViewDayCell class]) forIndexPath:self.currentIndexPath];
//    [dayCell.collectionView.collectionViewLayout invalidateLayout];
}


#pragma mark - UICollectionViewDataSource


- (NSInteger)collectionView:(UICollectionView *)collectionView
     numberOfItemsInSection:(NSInteger)section {
    return [self.calendar components:NSCalendarUnitDay
                            fromDate:self.startDateCache
                              toDate:self.endDateCache
                             options:0].day + 1;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView
                  cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    TodayCollectionViewDayCell *dayCell = (TodayCollectionViewDayCell *)[collectionView dequeueReusableCellWithReuseIdentifier:NSStringFromClass([TodayCollectionViewDayCell class]) forIndexPath:indexPath];
    dayCell.delegate = self;
    
    self.currentIndexPath = indexPath;
    
    self.dayComponents.day = indexPath.item;
    dayCell.selectedDate = [self.calendar dateByAddingComponents:self.dayComponents
                                                          toDate:self.startDateCache
                                                         options:0];
    [dayCell didSetSelectedDate];
    [self customizeDayLabelText];
    
    return dayCell;
}


#pragma mark - UICollectionViewDataSourcePrefetching


- (void)collectionView:(UICollectionView *)collectionView prefetchItemsAtIndexPaths:(NSArray<NSIndexPath *> *)indexPaths {
    
}


#pragma mark - UICollectionViewDelegateFlowLayout


- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    return self.collectionView.frame.size;
}


#pragma mark - UIScrollViewDelegate


- (void)scrollViewDidEndScrollingAnimation:(UIScrollView *)scrollView {
    [self scrollViewDidEndDecelerating:(UIScrollView *)self];
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    TodayCollectionViewDayCell *dayCell = self.collectionView.visibleCells.firstObject;
    self.todayLabel.text = [self.dateFormatter stringFromDate:dayCell.selectedDate];
    [[NSUserDefaults standardUserDefaults] setObject:dayCell.selectedDate forKey:@"dayDisplayed"];
}


#pragma mark - TodayCollectionViewDayCellDelegate


- (void)dayCell:(TodayCollectionViewDayCell *)cell didSelectEvent:(EKEvent *)ekEvent {
    EventPopUpViewController *eventPopUpVC = [[EventPopUpViewController alloc] initWithEvent:ekEvent delegate:self];
    [self presentViewController:eventPopUpVC animated:YES completion:nil];
}

- (CGFloat)sizeForSupplementaryView {
    return self.collectionView.frame.size.height / 12;
}


#pragma mark - EventPopUpDelegate


- (void)didDismissViewController {
}

- (void)editEventButtonPressedWithEvent:(EKEvent *)event {
    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:[[EditEventViewController alloc] initWithEvent:event]];
    [self presentViewController:navController animated:YES completion:nil];
}


#pragma mark - IBActions


- (IBAction)leftButtonTouched:(UIButton *)sender {
    [self updateDayByValue:-1];
}

- (IBAction)rightButtonTouched:(UIButton *)sender {
    [self updateDayByValue:1];
}

- (void)updateDayByValue:(NSInteger)value {
    NSDateComponents *valueComponents = [NSDateComponents new];
    valueComponents.day = value;
    
    for (TodayCollectionViewDayCell *dayCell in [self.collectionView visibleCells]) {
        NSDate *valueDate = [self.calendar dateByAddingComponents:valueComponents toDate:dayCell.selectedDate options:0];
        [self setDayDisplayed:valueDate animated:YES];
        dayCell.selectedDate = valueDate;
    }
}


#pragma mark - Private Methods


- (void)customizeDayLabelText {
    if (self.isFirstTimeLoadingView) {
        NSDate *currentDayDisplayed = [[NSUserDefaults standardUserDefaults] objectForKey:@"dayDisplayed"];
        NSNumber *initialScroll = [[NSUserDefaults standardUserDefaults] objectForKey:@"initialScrollDone"];
        
        NSDateComponents *comps = [NSDateComponents new];
        comps.day = 1;
        
        if (self.selectedLastViewController) {
            self.dayDisplayed = [NSDate date];
            self.selectedLastViewController = NO;
            
        } else if (self.selectedDate) {
            self.dayDisplayed = self.selectedDate;
            
        } else if (currentDayDisplayed && ![initialScroll boolValue]) {
            self.dayDisplayed = [self.calendar dateByAddingComponents:comps toDate:currentDayDisplayed options:0];
            
        } else if (currentDayDisplayed) {
            self.dayDisplayed = currentDayDisplayed;
            
        } else {
            // add an extra day to account for the UIScrollView offset
            self.dayDisplayed = [self.calendar dateByAddingComponents:comps toDate:[NSDate date] options:0];
        }
        
        self.selectedDate = self.dayDisplayed;
        self.todayLabel.text = [self.dateFormatter stringFromDate:self.dayDisplayed];
        
        [[NSUserDefaults standardUserDefaults] setObject:self.dayDisplayed forKey:@"dayDisplayed"];
        [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithBool:YES] forKey:@"initialScrollDone"];
        
        self.isFirstTimeLoadingView = NO;
    }
}

- (void)configureViewAndCollectionView {
    self.view.backgroundColor = [UIColor whiteColor];
    self.collectionView.backgroundColor = [UIColor clearColor];
    self.automaticallyAdjustsScrollViewInsets = NO;
    
    [self.collectionView registerClass:[TodayCollectionViewDayCell class]
            forCellWithReuseIdentifier:NSStringFromClass([TodayCollectionViewDayCell class])];
    
    [self.view addSubview:self.collectionView];
    
    self.definesPresentationContext = YES;
    self.isFirstTimeLoadingView = YES;
    self.collectionView.prefetchDataSource = self;
}

- (void)calculateStartAndEndDateCaches {
    NSDate *today = [NSDate date];
    NSDateComponents *comps = [NSDateComponents new];
    comps.year = -10;
    self.startDateCache = [self.calendar dateByAddingComponents:comps toDate:today options:0];
    
    comps.year = 10;
    self.endDateCache = [self.calendar dateByAddingComponents:comps toDate:today options:0];
}

- (TodayCollectionViewDayCell *)currentDayCell {
    CGFloat dayCellWidth = ((UICollectionViewFlowLayout *)self.collectionView.collectionViewLayout).itemSize.width;
    
    CGFloat pageNumberRoundedDown = floor(self.collectionView.contentOffset.x / dayCellWidth);
    
    return (TodayCollectionViewDayCell *)[self.collectionView cellForItemAtIndexPath:[NSIndexPath indexPathForItem:pageNumberRoundedDown inSection:0]];
}

- (NSUInteger)cellDisplayedIndex {
    return (NSUInteger)(self.collectionView.contentOffset.x / self.collectionView.frame.size.width);
}

- (NSDate *)dayDisplayed {
    NSDateComponents *comps = [NSDateComponents new];
    comps.day = self.cellDisplayedIndex;
    
    NSDate *day = [self.calendar dateByAddingComponents:comps toDate:self.startDateCache options:0];
    return day;
}

- (void)setDayDisplayed:(NSDate *)dayDisplayed animated:(BOOL)animated {
    NSDateComponents *differenceComponents = [self.calendar components:NSCalendarUnitDay
                                                              fromDate:self.startDateCache
                                                                toDate:dayDisplayed
                                                               options:0];
    if (differenceComponents.day != self.cellDisplayedIndex) {
        CGRect rectToScroll = CGRectZero;
        rectToScroll.size = self.collectionView.bounds.size;
        rectToScroll.origin.x = differenceComponents.day * self.collectionView.bounds.size.width;
        
        [self.collectionView scrollRectToVisible:rectToScroll animated:animated];
    }
}

- (void)setDayDisplayed:(NSDate *)dayDisplayed {
    [self setDayDisplayed:dayDisplayed animated:NO];
}

- (void)addTabBarNotificationObserver {
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(scrollToToday)
                                                 name:@"didSelectLastSelectedViewController"
                                               object:nil];
}

- (void)scrollToToday {
    NSDate *today = [NSDate date];
    [self setDayDisplayed:today animated:YES];
    self.selectedLastViewController = YES;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        self.todayLabel.text = [self.dateFormatter stringFromDate:today];
    });
}

- (void)addDataDidChangeNotificationObserver {
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(dataDidChange)
                                                 name:@"calendarOrEventDataDidChange"
                                               object:nil];
}

- (void)dataDidChange {
    [self.collectionView reloadData];
}


#pragma mark - Custom Getters


- (NSDateFormatter *)dateFormatter {
    if (!_dateFormatter) {
        _dateFormatter = [NSDateFormatter new];
        _dateFormatter.locale = [NSLocale currentLocale];
        [_dateFormatter setLocalizedDateFormatFromTemplate:@"E, MMM dYYYY"];
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

- (NSDateComponents *)dayComponents {
    if (!_dayComponents) {
        _dayComponents = [NSDateComponents new];
    }
    return _dayComponents;
}


@end
