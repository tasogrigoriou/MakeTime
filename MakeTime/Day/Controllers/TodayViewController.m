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
#import "SWRevealViewController.h"
#import "EventManager.h"
#import "AppDelegate.h"
#import "AddEventViewController.h"
#import "EventComponents.h"
#import "TodayCollectionViewDayCell.h"
#import "EditEventViewController.h"
#import "EventPopUpViewController.h"

@interface TodayViewController () <UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, UIScrollViewDelegate, TodayCollectionViewDayCellDelegate>

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

@end


@implementation TodayViewController


#pragma mark - View Lifecycle


- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self configureViewAndCollectionView];
    [self calculateStartAndEndDateCaches];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [super updateAuthorizationStatusToAccessEventStore];
    
//    self.navigationController.navigationBarHidden = YES;
//    self.navigationController.navigationBar.clipsToBounds = YES;
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    [self customizeDayLabelText];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    
    self.selectedDate = nil;
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    // Re-enable swipe when TodayVC disappears
    self.revealViewController.panGestureRecognizer.enabled = YES;
}

//- (void)viewWillTransitionToSize:(CGSize)size
//       withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
//    NSLog(@"transition cellDisplayedIndex = %li", self.cellDisplayedIndex);
//
//    [self.collectionView setContentOffset:CGPointMake(self.cellDisplayedIndex * self.view.bounds.size.height, 0) animated:NO];
//
//    NSLog(@"self.currentIndexPath = %li", self.currentIndexPath.item);
//    TodayCollectionViewDayCell *dayCell = (TodayCollectionViewDayCell *)[self.collectionView dequeueReusableCellWithReuseIdentifier:NSStringFromClass([TodayCollectionViewDayCell class]) forIndexPath:self.currentIndexPath];
//    [dayCell.collectionView.collectionViewLayout invalidateLayout];
//}

- (void)updateAuthorizationStatusToAccessEventStore {
    EKAuthorizationStatus authorizationStatus = [EKEventStore authorizationStatusForEntityType:EKEntityTypeEvent];
    switch (authorizationStatus) {
        case EKAuthorizationStatusDenied: {
        case EKAuthorizationStatusRestricted: {
            self.isAccessToEventStoreGranted = NO;
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Access Denied"
                                                                           message:@"This app doesn't have access to your Calendars. Please allow access in Settings"
                                                                    preferredStyle:UIAlertControllerStyleAlert];
            UIAlertAction *defaultAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault
                                                                  handler:^(UIAlertAction *action) {}];
            [alert addAction:defaultAction];
            [self presentViewController:alert animated:YES completion:nil];
            break;
        }
        }
        case EKAuthorizationStatusAuthorized: {
            self.isAccessToEventStoreGranted = YES;
            [[NSUserDefaults standardUserDefaults] setObject:@(self.isAccessToEventStoreGranted) forKey:@"eventStoreGranted"];
            break;
        }
        case EKAuthorizationStatusNotDetermined: {
            __weak TodayViewController *weakSelf = self;
            [self.appDelegate.eventManager.eventStore requestAccessToEntityType:EKEntityTypeEvent
                                                                     completion:^(BOOL granted, NSError *error) {
                                                                         dispatch_async(dispatch_get_main_queue(), ^{
                                                                             weakSelf.isAccessToEventStoreGranted = granted;
                                                                         });
                                                                     }];
            break;
        }
    }
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
    
    NSDateComponents *offsetComponents = [NSDateComponents new];
    offsetComponents.day = indexPath.item;
    dayCell.selectedDate = [self.calendar dateByAddingComponents:offsetComponents
                                                          toDate:self.startDateCache
                                                         options:0];
    [dayCell.collectionView reloadData];
    
    return dayCell;
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
    for (TodayCollectionViewDayCell *dayCell in [self.collectionView visibleCells]) {
        self.todayLabel.text = [self.dateFormatter stringFromDate:dayCell.selectedDate];
        [[NSUserDefaults standardUserDefaults] setObject:dayCell.selectedDate forKey:@"dayDisplayed"];
    }
}


#pragma mark - TodayCollectionViewDayCellDelegate


- (void)dayCell:(TodayCollectionViewDayCell *)cell didSelectEvent:(EKEvent *)ekEvent {
    //    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Event"
    //                                                                             message:[NSString stringWithFormat:@"%@ : %@", ekEvent.title, ekEvent.calendar.title]
    //                                                                      preferredStyle:UIAlertControllerStyleActionSheet];
    //
    //    UIAlertAction *editAction = [UIAlertAction actionWithTitle:@"Edit"
    //                                                         style:UIAlertActionStyleDefault
    //                                                       handler:^(UIAlertAction *action) {
    //                                                           EditEventViewController *editEventVC = [[EditEventViewController alloc] initWithEvent:ekEvent];
    //                                                           [self.navigationController pushViewController:editEventVC animated:YES];
    //                                                       }];
    //    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleDestructive
    //                                                         handler:^(UIAlertAction *action) {
    //                                                             [self dismissViewControllerAnimated:YES completion:nil];
    //                                                         }];
    //    [alertController addAction:editAction];
    //    [alertController addAction:cancelAction];
    //    [self presentViewController:alertController animated:YES completion:nil];
    
    
    self.definesPresentationContext = true;
    [self.navigationController presentViewController:[[EventPopUpViewController alloc] initWithStyle] animated:YES completion:nil];
}

- (CGFloat)sizeForSupplementaryView {
    return self.collectionView.frame.size.height / 12;
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
    NSDate *currentDayDisplayed = [[NSUserDefaults standardUserDefaults] objectForKey:@"dayDisplayed"];
    NSNumber *initialScroll = [[NSUserDefaults standardUserDefaults] objectForKey:@"initialScrollDone"];
    
    NSDateComponents *comps = [NSDateComponents new];
    comps.day = 1;
    
    if (self.selectedDate) {
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
}

- (void)configureViewAndCollectionView {
    self.view.backgroundColor = [UIColor whiteColor];
    self.collectionView.backgroundColor = [UIColor clearColor];
    self.automaticallyAdjustsScrollViewInsets = NO;
    
    // IMPORTANT property that requests our dayCell's ONLY when needed for display
    self.collectionView.prefetchingEnabled = NO;
    
    [self.collectionView registerClass:[TodayCollectionViewDayCell class]
            forCellWithReuseIdentifier:NSStringFromClass([TodayCollectionViewDayCell class])];
    
    [self.view addSubview:self.collectionView];
}

- (void)calculateStartAndEndDateCaches {
    NSDateComponents *comps = [NSDateComponents new];
    comps.year = -10;
    self.startDateCache = [self.calendar dateByAddingComponents:comps toDate:[NSDate date] options:0];
    
    comps.year = 10;
    self.endDateCache = [self.calendar dateByAddingComponents:comps toDate:[NSDate date] options:0];
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


#pragma mark - Custom Getters


- (NSDateFormatter *)dateFormatter {
    if (!_dateFormatter) {
        _dateFormatter = [NSDateFormatter new];
        _dateFormatter.locale = [NSLocale currentLocale];
        [_dateFormatter setLocalizedDateFormatFromTemplate:@"MMMMdYYYY"];
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
